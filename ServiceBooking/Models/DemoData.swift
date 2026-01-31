//
//  DemoData.swift
//  ServiceBooking
//
//  Демо-данные для режима без API (работают в Debug и Release)
//

import Foundation

enum DemoData {
    static let services: [Service] = [
        Service(id: "1", name: "Химчистка салона", description: "Полная химчистка салона автомобиля", price: 5000, duration: 180, category: "Автоуслуги", imageURL: nil, isActive: true),
        Service(id: "2", name: "Мойка кузова", description: "Бесконтактная мойка с воском", price: 800, duration: 30, category: "Автоуслуги", imageURL: nil, isActive: true),
        Service(id: "3", name: "Полировка", description: "Профессиональная полировка кузова", price: 8000, duration: 240, category: "Автоуслуги", imageURL: nil, isActive: true),
        Service(id: "4", name: "Полировка фар", description: "Восстановление прозрачности и блеска оптики", price: 1500, duration: 45, category: "Детейлинг", imageURL: nil, isActive: true),
        Service(id: "5", name: "Чистка дисков", description: "Мойка и полировка литых и кованых дисков", price: 2000, duration: 60, category: "Детейлинг", imageURL: nil, isActive: true),
    ]
    
    static let bookings: [Booking] = [
        Booking(id: "1", serviceId: "1", serviceName: "Химчистка салона", userId: "u1", dateTime: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(), status: .confirmed, price: 5000, duration: 180, notes: nil, createdAt: Date()),
        Booking(id: "2", serviceId: "4", serviceName: "Полировка фар", userId: "u1", dateTime: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(), status: .pending, price: 1500, duration: 45, notes: nil, createdAt: Date()),
        Booking(id: "3", serviceId: "2", serviceName: "Мойка кузова", userId: "u1", dateTime: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(), status: .completed, price: 800, duration: 30, notes: nil, createdAt: Date()),
    ]
    
    static let user = User(
        id: "demo",
        firstName: "Александр",
        lastName: "Иванов",
        phone: "+7 (999) 123-45-67",
        email: "alex@example.com",
        avatarURL: nil,
        socialLinks: SocialLinks(telegram: "@alex", whatsapp: "+79991234567", instagram: "alex.ivanov", vk: "alexivanov"),
        createdAt: Date()
    )
    
    static let posts: [Post] = [
        Post(id: "post_1", name: "Пост 1", isEnabled: true, useCustomHours: false, startTime: "09:00", endTime: "18:00", intervalMinutes: 30),
        Post(id: "post_2", name: "Пост 2", isEnabled: true, useCustomHours: false, startTime: "09:00", endTime: "18:00", intervalMinutes: 30),
    ]
}
