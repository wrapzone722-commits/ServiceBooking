//
//  Booking.swift
//  ServiceBooking
//
//  Модель записи (данные приходят с сервера)
//

import Foundation

/// Статус записи
enum BookingStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case confirmed = "confirmed"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Ожидает"
        case .confirmed: return "Подтверждена"
        case .inProgress: return "В процессе"
        case .completed: return "Завершена"
        case .cancelled: return "Отменена"
        }
    }
}

/// Модель записи
struct Booking: Identifiable, Codable {
    let id: String
    let serviceId: String
    let serviceName: String
    let userId: String
    let dateTime: Date
    let status: BookingStatus
    let price: Double
    let duration: Int
    let notes: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case serviceId = "service_id"
        case serviceName = "service_name"
        case userId = "user_id"
        case dateTime = "date_time"
        case status
        case price
        case duration
        case notes
        case createdAt = "created_at"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: dateTime)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: dateTime)
    }
    
    var formattedPrice: String {
        String(format: "%.0f ₽", price)
    }
    
    var isPast: Bool { dateTime < Date() }
    var canCancel: Bool { status == .pending || status == .confirmed }
}

/// Запрос на создание записи (по спецификации веб-консоли)
struct CreateBookingRequest: Codable {
    let serviceId: String
    let dateTime: Date
    let postId: String
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case serviceId = "service_id"
        case dateTime = "date_time"
        case postId = "post_id"
        case notes
    }
}

/// Слот времени
struct TimeSlot: Identifiable, Codable, Hashable {
    let id: String
    let time: Date
    let isAvailable: Bool
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    /// Декодирование формата API: { "time": "ISO8601", "is_available": bool }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode(Date.self, forKey: .time)
        isAvailable = try container.decode(Bool.self, forKey: .isAvailable)
        id = ISO8601DateFormatter().string(from: time)
    }
    
    init(id: String, time: Date, isAvailable: Bool) {
        self.id = id
        self.time = time
        self.isAvailable = isAvailable
    }
    
    enum CodingKeys: String, CodingKey {
        case time
        case isAvailable = "is_available"
    }
}

// MARK: - Preview Data
#if DEBUG
extension Booking {
    static let preview: [Booking] = [
        Booking(id: "1", serviceId: "1", serviceName: "Химчистка салона", userId: "u1", dateTime: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, status: .confirmed, price: 5000, duration: 180, notes: nil, createdAt: Date()),
        Booking(id: "2", serviceId: "4", serviceName: "Полировка фар", userId: "u1", dateTime: Calendar.current.date(byAdding: .day, value: 5, to: Date())!, status: .pending, price: 1500, duration: 45, notes: nil, createdAt: Date()),
        Booking(id: "3", serviceId: "2", serviceName: "Мойка кузова", userId: "u1", dateTime: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, status: .completed, price: 800, duration: 30, notes: nil, createdAt: Date()),
    ]
}
#endif
