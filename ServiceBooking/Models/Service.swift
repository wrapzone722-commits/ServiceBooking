//
//  Service.swift
//  ServiceBooking
//
//  Модель услуги (данные приходят с сервера)
//

import Foundation

/// Модель услуги
struct Service: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let duration: Int // минуты
    let category: String
    let imageURL: String?
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case description
        case price
        case duration
        case category
        case imageURL = "image_url"
        case isActive = "is_active"
    }
    
    var formattedPrice: String {
        String(format: "%.0f ₽", price)
    }
    
    var formattedDuration: String {
        if duration >= 60 {
            let hours = duration / 60
            let minutes = duration % 60
            return minutes > 0 ? "\(hours) ч \(minutes) мин" : "\(hours) ч"
        }
        return "\(duration) мин"
    }
}

/// Категория услуг
struct ServiceCategory: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let icon: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case icon
    }
}

// MARK: - Preview Data (только для SwiftUI Preview, НЕ для production)
#if DEBUG
extension Service {
    static let preview: [Service] = [
        Service(id: "1", name: "Химчистка салона", description: "Полная химчистка салона автомобиля", price: 5000, duration: 180, category: "Автоуслуги", imageURL: nil, isActive: true),
        Service(id: "2", name: "Мойка кузова", description: "Бесконтактная мойка с воском", price: 800, duration: 30, category: "Автоуслуги", imageURL: nil, isActive: true),
        Service(id: "3", name: "Полировка", description: "Профессиональная полировка кузова", price: 8000, duration: 240, category: "Автоуслуги", imageURL: nil, isActive: true),
        Service(id: "4", name: "Полировка фар", description: "Восстановление прозрачности и блеска оптики", price: 1500, duration: 45, category: "Детейлинг", imageURL: nil, isActive: true),
        Service(id: "5", name: "Чистка дисков", description: "Мойка и полировка литых и кованых дисков", price: 2000, duration: 60, category: "Детейлинг", imageURL: nil, isActive: true),
    ]
}
#endif
