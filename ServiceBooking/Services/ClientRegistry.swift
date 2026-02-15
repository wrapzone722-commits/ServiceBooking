//
//  ClientRegistry.swift
//  ServiceBooking
//
//  Регистрация клиента в веб-консоли — получение уникального API-ключа
//

import Foundation
import UIKit

/// Ответ регистрации клиента
struct RegisterClientResponse: Codable {
    let clientId: String
    let apiKey: String
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case apiKey = "api_key"
    }
}

/// Запрос регистрации клиента
struct RegisterClientRequest: Encodable {
    let deviceId: String
    let platform: String
    let appVersion: String
    
    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case platform
        case appVersion = "app_version"
    }
}

/// Регистрация устройства и получение уникального API-ключа
enum ClientRegistry {
    /// Уникальный ID устройства (генерируется при первом запуске, хранится в Keychain)
    static var deviceId: String {
        KeychainStorage.deviceId
    }
    
    /// Сессия с поддержкой VPN: ожидание подключения, увеличенный таймаут
    private static var sharedSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()
    
    /// Зарегистрировать клиента в веб-консоли и получить API-ключ
    static func register(baseURL: String) async throws -> RegisterClientResponse {
        let urlString = baseURL.hasSuffix("/") ? baseURL + "clients/register" : baseURL + "/clients/register"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let request = RegisterClientRequest(
            deviceId: deviceId,
            platform: await MainActor.run { "iOS \(UIDevice.current.systemVersion)" },
            appVersion: await MainActor.run { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 60
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await sharedSession.data(for: urlRequest)
        } catch {
            throw APIError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let response = try decoder.decode(RegisterClientResponse.self, from: data)
            KeychainStorage.apiKey = response.apiKey
            KeychainStorage.clientId = response.clientId
            return response
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.serverError(404, "Эндпоинт /clients/register не найден (404). Проверьте URL — возможно, это не Service Booking API.")
        default:
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw APIError.serverError(httpResponse.statusCode, raw.isEmpty ? "Код \(httpResponse.statusCode)" : raw)
        }
    }
}
