//
//  ConsoleConfig.swift
//  ServiceBooking
//
//  Конфигурация веб-консоли после сканирования QR
//  api_key хранится в Keychain (KeychainStorage)
//

import Foundation

/// Конфигурация подключения к веб-консоли
struct ConsoleConfig: Codable {
    let baseURL: String
    let scannedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case baseURL = "base_url"
        case scannedAt = "scanned_at"
    }
}

/// Хранилище конфигурации
final class ConsoleConfigStorage {
    static let shared = ConsoleConfigStorage()
    
    private let key = "service_booking_console_config"
    
    private init() {}
    
    /// Конфигурация подключена?
    var hasConfig: Bool {
        config != nil
    }
    
    /// Текущая конфигурация (baseURL)
    var config: ConsoleConfig? {
        get {
            guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(ConsoleConfig.self, from: data)
        }
        set {
            if let config = newValue, let data = try? JSONEncoder().encode(config) {
                UserDefaults.standard.set(data, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
    
    /// Токен авторизации (из Keychain)
    var token: String? {
        KeychainStorage.apiKey
    }
    
    /// Сохранить конфигурацию после сканирования QR
    /// token сохраняется в Keychain
    func save(baseURL: String, token: String? = nil) {
        let normalizedURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let config = ConsoleConfig(baseURL: normalizedURL, scannedAt: Date())
        self.config = config
        if let token = token, !token.isEmpty {
            KeychainStorage.apiKey = token
        }
    }
    
    /// Сбросить конфигурацию и учётные данные
    func reset() {
        config = nil
        KeychainStorage.clearCredentials()
        APIService.shared.clearAuthToken()
    }
}
