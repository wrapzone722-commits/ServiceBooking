//
//  Car.swift
//  ServiceBooking
//
//  Модель папки автомобиля (тип/модель из веб-консоли)
//

import Foundation

/// Элемент изображения в папке (имя файла + URL)
struct CarImageItem: Codable {
    let name: String
    let url: String
}

/// Папка/тип автомобиля (список в веб-консоли)
struct Car: Identifiable, Codable {
    let id: String
    let name: String
    let imageURL: String?
    /// Все изображения папки (01, 02, 03, 04 и др.) для выбора по правилу отображения
    let images: [CarImageItem]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case imageURL = "image_url"
        case images
    }

    init(id: String, name: String, imageURL: String?, images: [CarImageItem] = []) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.images = images
    }

    /// Имя файла без расширения (01.jpg, 01.png, 02.JPG → "01", "02"). Поддерживаются любые расширения.
    static func baseName(_ fileName: String) -> String {
        (fileName as NSString).deletingPathExtension
    }

    /// URL изображения по предпочитаемому имени (01/02/03/04); сравнение по базовому имени, расширение может быть .jpg, .png и т.д.
    func urlForDisplayPhoto(preferredBaseName: String) -> String? {
        let order = ["01", "02", "03", "04"]
        let byBase = Dictionary(uniqueKeysWithValues: images.map { (Self.baseName($0.name), $0.url) })
        if let url = byBase[preferredBaseName] { return url }
        for name in order {
            if let url = byBase[name] { return url }
        }
        return images.first?.url
    }
}

/// Ответ API /api/v1/cars/folders (консоль)
struct CarFolderResponse: Codable {
    let id: String
    let name: String
    let images: [CarImageResponse]
    let profilePreviewURL: String?
    let profilePreviewThumbnailURL: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case images
        case profilePreviewURL = "profile_preview_url"
        case profilePreviewThumbnailURL = "profile_preview_thumbnail_url"
    }
}

struct CarImageResponse: Codable {
    let name: String
    let url: String
    let thumbnailURL: String?

    enum CodingKeys: String, CodingKey {
        case name
        case url
        case thumbnailURL = "thumbnail_url"
    }
}
