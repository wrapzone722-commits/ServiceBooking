//
//  ServiceChatMessage.swift
//  ServiceBooking
//
//  Сообщения от веб-консоли: сервисные уведомления и сообщения администратора.
//  Загружаются с API (GET /notifications), в демо — из DemoData + локальный кэш.
//

import Foundation

/// Источник сообщения: сервис (система) или администратор
enum MessageSource: String, Codable, CaseIterable {
    case service = "service"
    case admin = "admin"
    case news = "news"
    
    var displayName: String {
        switch self {
        case .service: return "Сервис"
        case .admin: return "Администратор"
        case .news: return "Новости"
        }
    }
    
    var iconName: String {
        switch self {
        case .service: return "bell.fill"
        case .admin: return "person.fill"
        case .news: return "newspaper.fill"
        }
    }
}

struct ServiceChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let date: Date
    let isFromService: Bool
    var title: String?
    var source: MessageSource
    var isRead: Bool
    
    init(
        id: String = UUID().uuidString,
        text: String,
        date: Date = Date(),
        isFromService: Bool = true,
        title: String? = nil,
        source: MessageSource = .service,
        isRead: Bool = false
    ) {
        self.id = id
        self.text = text
        self.date = date
        self.isFromService = isFromService
        self.title = title
        self.source = source
        self.isRead = isRead
    }
    
    /// Декодирование из UserDefaults (могут отсутствовать title, source, isRead)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        date = try c.decode(Date.self, forKey: .date)
        isFromService = try c.decodeIfPresent(Bool.self, forKey: .isFromService) ?? true
        title = try c.decodeIfPresent(String.self, forKey: .title)
        let raw = try c.decodeIfPresent(String.self, forKey: .source)
        source = raw.flatMap { MessageSource(rawValue: $0) } ?? .service
        isRead = try c.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(text, forKey: .text)
        try c.encode(date, forKey: .date)
        try c.encode(isFromService, forKey: .isFromService)
        try c.encodeIfPresent(title, forKey: .title)
        try c.encode(source.rawValue, forKey: .source)
        try c.encode(isRead, forKey: .isRead)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, text, date, isFromService, title, source, isRead
    }
}

/// Ответ API: уведомления (snake_case)
struct APINotificationItem: Decodable {
    let _id: String
    let body: String
    let created_at: Date
    let type: String?
    let title: String?
    let read: Bool?
    
    func toMessage() -> ServiceChatMessage {
        ServiceChatMessage(
            id: _id,
            text: body,
            date: created_at,
            isFromService: true,
            title: title,
            source: MessageSource(rawValue: type ?? "service") ?? .service,
            isRead: read ?? false
        )
    }
}

/// Локальное хранилище истории сервисного чата
final class ServiceChatStorage {
    static let shared = ServiceChatStorage()
    private let key = "service_booking_chat_messages"
    private let maxMessages = 500
    
    private init() {}
    
    var messages: [ServiceChatMessage] {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let decoded = try? JSONDecoder().decode([ServiceChatMessage].self, from: data) else {
                return []
            }
            return decoded.sorted { $0.date < $1.date }
        }
        set {
            let toSave = Array(newValue.suffix(maxMessages))
            if let data = try? JSONEncoder().encode(toSave) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }
    
    func append(_ message: ServiceChatMessage) {
        var current = messages
        current.append(message)
        messages = current
    }
    
    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
