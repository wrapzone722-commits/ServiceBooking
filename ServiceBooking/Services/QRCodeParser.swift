//
//  QRCodeParser.swift
//  ServiceBooking
//
//  Парсинг содержимого QR-кода веб-консоли
//

import Foundation

/// Результат парсинга QR-кода
struct QRParseResult {
    let baseURL: String
    let token: String?
}

enum QRCodeParser {
    
    /// Распарсить содержимое QR-кода
    /// Поддерживает: URL, JSON, servicebooking://
    static func parse(_ string: String) -> QRParseResult? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. JSON: {"base_url": "...", "token": "..."}
        if trimmed.hasPrefix("{") {
            return parseJSON(trimmed)
        }
        
        // 2. Custom scheme: servicebooking://config?url=...&token=...
        if trimmed.lowercased().hasPrefix("servicebooking://") {
            return parseCustomScheme(trimmed)
        }
        
        // 3. Обычный HTTPS URL
        if trimmed.lowercased().hasPrefix("http") {
            return parseURL(trimmed)
        }
        
        return nil
    }
    
    private static func parseJSON(_ string: String) -> QRParseResult? {
        guard let data = string.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let baseURL = json["base_url"] as? String ?? json["url"] as? String,
              isValidURL(baseURL) else {
            return nil
        }
        let token = json["token"] as? String ?? json["access_token"] as? String
        return QRParseResult(baseURL: normalizeURL(baseURL), token: token?.isEmpty == true ? nil : token)
    }
    
    private static func parseCustomScheme(_ string: String) -> QRParseResult? {
        guard let url = URL(string: string),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        var baseURL: String?
        var token: String?
        
        for item in queryItems {
            if item.name == "url" || item.name == "base_url", let value = item.value {
                baseURL = value
            } else if item.name == "token" || item.name == "access_token", let value = item.value {
                token = value
            }
        }
        
        guard let urlString = baseURL, isValidURL(urlString) else {
            return nil
        }
        
        return QRParseResult(baseURL: normalizeURL(urlString), token: token)
    }
    
    private static func parseURL(_ string: String) -> QRParseResult? {
        guard isValidURL(string) else { return nil }
        
        // Убираем / в конце, оставляем путь /v1 если есть
        let normalized = normalizeURL(string)
        return QRParseResult(baseURL: normalized, token: nil)
    }
    
    private static func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme == "https" || url.scheme == "http"
    }
    
    private static func normalizeURL(_ string: String) -> String {
        var result = string
        if result.hasSuffix("/") {
            result = String(result.dropLast())
        }
        return result
    }
}
