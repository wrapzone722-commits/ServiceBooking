//
//  CompressedRemoteImage.swift
//  ServiceBooking
//
//  Загрузка изображений с экономией трафика (превью через API) и памяти (даунсэмплинг).
//

import ImageIO
import SwiftUI
import UIKit

enum ImageDownsampler {
    static func downsample(data: Data, maxDimension: CGFloat) -> UIImage? {
        let maxD = max(64, min(maxDimension, 4096))
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxD),
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        guard let src = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary)
        else { return nil }
        return UIImage(cgImage: cg)
    }
}

private enum RemoteImageMemoryCache {
    private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 80
        return c
    }()

    static func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    static func set(_ image: UIImage, key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

struct CompressedRemoteImage: View {
    let urlString: String?
    var maxPixelSide: CGFloat = 400
    var contentMode: ContentMode = .fill

    @State private var uiImage: UIImage?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let img = uiImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if loadFailed {
                Color(.tertiarySystemFill)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: urlString) {
            await load()
        }
    }

    private func load() async {
        uiImage = nil
        loadFailed = false
        guard let raw = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            loadFailed = true
            return
        }

        let pixelTarget = Int(maxPixelSide * UIScreen.main.scale)
        let maxDim = maxPixelSide * UIScreen.main.scale

        // data: URI → decode inline without network
        if raw.lowercased().hasPrefix("data:image/") {
            if let data = Self.decodeDataURI(raw) {
                let cacheKey = "data_\(data.hashValue)_\(pixelTarget)"
                if let cached = RemoteImageMemoryCache.image(forKey: cacheKey) {
                    uiImage = cached
                    return
                }
                if let img = ImageDownsampler.downsample(data: data, maxDimension: maxDim) ?? UIImage(data: data) {
                    RemoteImageMemoryCache.set(img, key: cacheKey)
                    uiImage = img
                    return
                }
            }
            loadFailed = true
            return
        }

        let resolved = APIService.resolvedImageURLString(raw)
        guard let absolute = resolved, let directURL = Self.safeURL(absolute) else {
            loadFailed = true
            return
        }

        let previewURL = APIService.compressedPreviewURL(original: raw, maxPixelWidth: pixelTarget)
        let cacheKey = "\(previewURL?.absoluteString ?? directURL.absoluteString)_\(pixelTarget)"
        if let cached = RemoteImageMemoryCache.image(forKey: cacheKey) {
            uiImage = cached
            return
        }

        let usePreview = previewURL != nil && previewURL != directURL
        var data: Data?

        if let p = previewURL, usePreview {
            do {
                data = try await APIService.shared.loadImageData(url: p, useAPIAuth: true)
            } catch {
                data = nil
            }
        }

        if data == nil {
            // Try with API auth first (works for relative /uploads/ paths on same host)
            do {
                data = try await APIService.shared.loadImageData(url: directURL, useAPIAuth: true)
            } catch {
                data = nil
            }
        }

        if data == nil {
            // Final attempt: no auth (external hosts)
            do {
                data = try await APIService.shared.loadImageData(url: directURL, useAPIAuth: false)
            } catch {
                loadFailed = true
                return
            }
        }

        guard let d = data, !d.isEmpty else {
            loadFailed = true
            return
        }
        let img = ImageDownsampler.downsample(data: d, maxDimension: maxDim)
            ?? UIImage(data: d)
        if let img {
            RemoteImageMemoryCache.set(img, key: cacheKey)
            uiImage = img
        } else {
            loadFailed = true
        }
    }

    // MARK: - Helpers

    /// Parse `data:image/...;base64,...` into raw bytes.
    private static func decodeDataURI(_ uri: String) -> Data? {
        guard let commaIndex = uri.firstIndex(of: ",") else { return nil }
        let base64 = String(uri[uri.index(after: commaIndex)...])
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }

    /// Build a URL, applying percent-encoding for non-ASCII characters if needed.
    private static func safeURL(_ string: String) -> URL? {
        if let url = URL(string: string) { return url }
        if let encoded = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encoded) { return url }
        return nil
    }
}
