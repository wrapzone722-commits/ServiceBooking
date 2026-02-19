//
//  APIService.swift
//  ServiceBooking
//
//  Сервис для работы с API
//  ВСЕ данные получаются с сервера, локальное хранение НЕ используется
//

import Foundation

/// Ошибки API
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(Int, String?)
    case unauthorized
    case noConnection
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .noData:
            return "Нет данных от сервера"
        case .decodingError:
            return "Ошибка обработки данных — формат ответа API не соответствует ожидаемому. Проверьте URL или используйте демо-режим."
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Ошибка сервера (\(code)): \(message ?? "Неизвестная ошибка")"
        case .unauthorized:
            return "Необходима авторизация"
        case .noConnection:
            return "Нет подключения к интернету"
        }
    }
}

/// Конфигурация API
struct APIConfig {
    /// URL по умолчанию (до сканирования QR). Должен заканчиваться на /api/v1.
    static let defaultBaseURL = "https://api.your-service.com/api/v1"
    
    /// Текущий URL — из QR или default
    static var baseURL: String {
        ConsoleConfigStorage.shared.config?.baseURL ?? defaultBaseURL
    }
    
    /// Таймаут запросов (секунды); увеличен для работы через VPN
    static let requestTimeout: TimeInterval = 60
    
    /// Ручной переопределение (nil = считать по конфигу)
    private static var _useMockDataOverride: Bool?

    /// Демо-режим: по умолчанию из конфига; можно переопределить из UI
    static var useMockData: Bool {
        get {
            if let override = _useMockDataOverride { return override }
            guard let config = ConsoleConfigStorage.shared.config else { return true }
            let url = config.baseURL.trimmingCharacters(in: .whitespaces)
            return url.isEmpty || url == defaultBaseURL
        }
        set { _useMockDataOverride = newValue }
    }

    /// Сбросить переопределение — снова использовать значение по конфигу
    static func resetUseMockDataOverride() {
        _useMockDataOverride = nil
    }
}

/// Основной сервис для работы с API
/// Приложение НЕ хранит данные локально - всё получается с сервера
class APIService {
    static let shared = APIService()
    
    private var authToken: String?
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let session: URLSession
    
    private init() {
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        
        // Конфигурация сессии: работа через VPN, ожидание подключения
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        config.timeoutIntervalForRequest = APIConfig.requestTimeout
        config.timeoutIntervalForResource = 120 // Ожидание при медленном/VPN-подключении
        config.waitsForConnectivity = true // Не падать сразу; ждать появления сети (в т.ч. VPN)
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Configuration
    
    /// Установить токен авторизации
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    /// Очистить токен (выход)
    func clearAuthToken() {
        self.authToken = nil
    }
    
    /// Проверить есть ли токен
    var isAuthenticated: Bool {
        return authToken != nil
    }
    
    // MARK: - Services API
    
    /// Получить список услуг (всегда с сервера)
    func fetchServices() async throws -> [Service] {
        if APIConfig.useMockData {
            try await Task.sleep(nanoseconds: 300_000_000)
            return DemoData.services
        }
        return try await request(endpoint: "/services", method: "GET")
    }
    
    /// Получить детали услуги
    func fetchService(id: String) async throws -> Service {
        if APIConfig.useMockData {
            try await Task.sleep(nanoseconds: 200_000_000)
            guard let service = DemoData.services.first(where: { $0.id == id }) else {
                throw APIError.noData
            }
            return service
        }
        return try await request(endpoint: "/services/\(id)", method: "GET")
    }
    
    // MARK: - Bookings API
    
    /// Получить записи пользователя (всегда с сервера)
    func fetchBookings() async throws -> [Booking] {
        if APIConfig.useMockData {
            try await Task.sleep(nanoseconds: 300_000_000)
            return DemoData.bookings
        }
        return try await request(endpoint: "/bookings", method: "GET")
    }
    
    /// Создать запись
    func createBooking(request: CreateBookingRequest) async throws -> Booking {
        if APIConfig.useMockData {
            try await Task.sleep(nanoseconds: 400_000_000)
            let service = DemoData.services.first { $0.id == request.serviceId }
            return Booking(
                id: UUID().uuidString,
                serviceId: request.serviceId,
                serviceName: service?.name ?? "Услуга",
                userId: "demo_user",
                dateTime: request.dateTime,
                status: .pending,
                price: service?.price ?? 0,
                duration: service?.duration ?? 60,
                notes: request.notes,
                createdAt: Date(),
                inProgressStartedAt: nil
            )
        }
        return try await self.request(
            endpoint: "/bookings",
            method: "POST",
            body: request
        )
    }
    
    /// Отправить рейтинг по записи (POST /bookings/:id/rating)
    func submitRating(bookingId: String, rating: Int, comment: String? = nil) async throws {
        if APIConfig.useMockData {
            try await Task.sleep(nanoseconds: 200_000_000)
            return
        }
        struct RatingRequest: Encodable {
            let rating: Int
            let comment: String?
        }
        struct RatingResponse: Decodable {
            let rating: Int
            let rating_comment: String?
        }
        let _: RatingResponse = try await request(
            endpoint: "/bookings/\(bookingId)/rating",
            method: "POST",
            body: RatingRequest(rating: rating, comment: comment)
        )
    }

    /// Отменить запись
    func cancelBooking(id: String) async throws {
        if APIConfig.useMockData {
            try await Task.sleep(nanoseconds: 300_000_000)
            return
        }
        let _: EmptyResponse = try await request(
            endpoint: "/bookings/\(id)",
            method: "DELETE"
        )
    }
    
    /// Скачать PDF «Акт выполненных работ» для завершённой записи (GET .../bookings/:id/act)
    func fetchBookingAct(bookingId: String) async throws -> Data {
        if APIConfig.useMockData {
            throw APIError.serverError(404, "Акт доступен только при подключении к серверу")
        }
        return try await requestRaw(endpoint: "/bookings/\(bookingId)/act", method: "GET")
    }
    
    // MARK: - Time Slots API
    
    /// Получить доступные слоты (по спецификации: service_id, date, post_id)
    func fetchAvailableSlots(serviceId: String, date: Date, postId: String = "post_1") async throws -> [TimeSlot] {
        if APIConfig.useMockData {
            try await Task.sleep(nanoseconds: 300_000_000)
            return generateDemoSlots(for: date)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        
        let encodedServiceId = serviceId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? serviceId
        let encodedPostId = postId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? postId
        
        return try await request(
            endpoint: "/slots?service_id=\(encodedServiceId)&date=\(dateString)&post_id=\(encodedPostId)",
            method: "GET"
        )
    }
    
    // MARK: - Posts API
    
    /// Получить список постов (боксов)
    func fetchPosts() async throws -> [Post] {
        if APIConfig.useMockData {
            try await Task.sleep(nanoseconds: 200_000_000)
            return DemoData.posts
        }
        return try await request(endpoint: "/posts", method: "GET")
    }
    
    /// Получить список папок автомобилей (типы авто из веб-консоли) — GET /api/v1/cars/folders
    func fetchCars() async throws -> [Car] {
        if APIConfig.useMockData {
            try await Task.sleep(nanoseconds: 150_000_000)
            return DemoData.cars
        }
        let folders: [CarFolderResponse] = try await request(endpoint: "/cars/folders", method: "GET")
        return folders.map { folder in
            let items = folder.images.map { CarImageItem(name: $0.name, url: $0.url) }
            return Car(
                id: folder.id,
                name: folder.name,
                imageURL: folder.profilePreviewURL ?? folder.images.first?.url,
                images: items
            )
        }
    }

    // MARK: - Profile API

    /// Получить профиль (всегда с сервера)
    func fetchProfile() async throws -> User {
        if APIConfig.useMockData {
            try await Task.sleep(nanoseconds: 200_000_000)
            return DemoData.user
        }
        return try await request(endpoint: "/profile", method: "GET")
    }
    
    /// Обновить профиль
    func updateProfile(request: UpdateProfileRequest) async throws -> User {
        if APIConfig.useMockData {
            try await Task.sleep(nanoseconds: 300_000_000)
            var user = DemoData.user
            if let firstName = request.firstName { user.firstName = firstName }
            if let lastName = request.lastName { user.lastName = lastName }
            if let email = request.email { user.email = email }
            if let carId = request.selectedCarId {
                user.selectedCarId = carId
                if let car = DemoData.cars.first(where: { $0.id == carId }), let url = car.imageURL {
                    user.avatarURL = url
                }
            }
            return user
        }
        return try await self.request(
            endpoint: "/profile",
            method: "PUT",
            body: request
        )
    }
    
    // MARK: - Уведомления (сообщения от веб-консоли: сервисные и от администратора)
    
    /// Получить список уведомлений/сообщений для текущего клиента
    func fetchNotifications() async throws -> [ServiceChatMessage] {
        if APIConfig.useMockData {
            try await Task.sleep(nanoseconds: 250_000_000)
            return DemoData.notifications
        }
        let list: [APINotificationItem] = try await request(endpoint: "/notifications", method: "GET")
        return list.map { $0.toMessage() }
    }
    
    /// Отметить уведомление как прочитанное (опционально, для веб-консоли)
    func markNotificationRead(id: String) async throws {
        if APIConfig.useMockData { return }
        let _: EmptyResponse = try await request(
            endpoint: "/notifications/\(id)/read",
            method: "PATCH"
        )
    }
    
    // MARK: - Новости (GET /news)
    
    func fetchNews() async throws -> [ClientNewsItem] {
        if APIConfig.useMockData {
            try await Task.sleep(nanoseconds: 250_000_000)
            return [] // демо при необходимости добавим позже
        }
        return try await request(endpoint: "/news", method: "GET")
    }
    
    // MARK: - Private Methods
    
    /// Запрос, возвращающий сырые данные (для PDF и т.п.)
    private func requestRaw(endpoint: String, method: String) async throws -> Data {
        guard let url = URL(string: APIConfig.baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let token = authToken ?? KeychainStorage.apiKey
        if let token = token, !token.isEmpty {
            request.setValue(token, forHTTPHeaderField: "X-API-Key")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1))
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = Self.parseServerErrorMessage(data: data)
            throw APIError.serverError(httpResponse.statusCode, message)
        }
        return data
    }
    
    /// Выполнить запрос к API (без кэширования)
    private func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: (any Encodable)? = nil
    ) async throws -> T {
        // Не блокируем запрос по NWPathMonitor — при VPN он может давать ложный «нет сети».
        // URLSession с waitsForConnectivity сам дождётся подключения или вернёт ошибку по таймауту.
        guard let url = URL(string: APIConfig.baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // Авторизация: X-API-Key (консоль) и Bearer для совместимости
        let token = authToken ?? KeychainStorage.apiKey
        if let token = token, !token.isEmpty {
            request.setValue(token, forHTTPHeaderField: "X-API-Key")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Тело запроса
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError
            }
        case 401:
            throw APIError.unauthorized
        default:
            let message = Self.parseServerErrorMessage(data: data)
            throw APIError.serverError(httpResponse.statusCode, message)
        }
    }
    
    /// Извлечь сообщение об ошибке из JSON ответа сервера (поле "message" или "error")
    private static func parseServerErrorMessage(data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let msg = json["message"] as? String ?? json["error"] as? String {
            return msg
        }
        return String(data: data, encoding: .utf8)
    }
    
    /// Демо слоты для тестирования UI
    private func generateDemoSlots(for date: Date) -> [TimeSlot] {
        var slots: [TimeSlot] = []
        let calendar = Calendar.current
        
        for hour in 9..<20 {
            for minute in [0, 30] {
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = hour
                components.minute = minute
                
                if let slotTime = calendar.date(from: components) {
                    slots.append(TimeSlot(
                        id: "\(hour):\(minute)",
                        time: slotTime,
                        isAvailable: Bool.random()
                    ))
                }
            }
        }
        return slots
    }
}

private struct EmptyResponse: Decodable {}
