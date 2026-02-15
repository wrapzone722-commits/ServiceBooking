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
        Booking(id: "1", serviceId: "1", serviceName: "Химчистка салона", userId: "u1", dateTime: Date(), status: .inProgress, price: 5000, duration: 180, notes: "Требуется особое внимание к заднему сиденью", createdAt: Date(), inProgressStartedAt: Date()),
        Booking(id: "2", serviceId: "4", serviceName: "Полировка фар", userId: "u1", dateTime: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(), status: .pending, price: 1500, duration: 45, notes: nil, createdAt: Date(), inProgressStartedAt: nil),
        Booking(id: "3", serviceId: "2", serviceName: "Мойка кузова", userId: "u1", dateTime: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(), status: .confirmed, price: 800, duration: 30, notes: nil, createdAt: Date(), inProgressStartedAt: nil),
        Booking(id: "4", serviceId: "3", serviceName: "Полировка кузова", userId: "u1", dateTime: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(), status: .completed, price: 8000, duration: 240, notes: nil, createdAt: Date(), inProgressStartedAt: nil),
    ]
    
    static let user = User(
        id: "demo",
        firstName: "Александр",
        lastName: "Иванов",
        phone: "+7 (999) 123-45-67",
        email: "alex@example.com",
        avatarURL: nil,
        selectedCarId: nil,
        socialLinks: SocialLinks(telegram: "@alex", vk: "alexivanov"),
        createdAt: Date(),
        loyaltyPoints: 350,
        clientTier: .regular,
        displayPhotoName: "01"
    )

    static let cars: [Car] = [
        Car(id: "1", name: "Седан", imageURL: nil, images: []),
        Car(id: "2", name: "Кроссовер", imageURL: nil, images: []),
        Car(id: "3", name: "Хэтчбек", imageURL: nil, images: []),
        Car(id: "4", name: "Внедорожник", imageURL: nil, images: []),
    ]
    
    static let posts: [Post] = [
        Post(id: "post_1", name: "Пост 1", isEnabled: true, useCustomHours: false, startTime: "09:00", endTime: "18:00", intervalMinutes: 30),
        Post(id: "post_2", name: "Пост 2", isEnabled: true, useCustomHours: false, startTime: "09:00", endTime: "18:00", intervalMinutes: 30),
    ]
    
    /// Демо-уведомления: сервисные и от администратора (как с веб-консоли)
    static let notifications: [ServiceChatMessage] = [
        ServiceChatMessage(
            id: "n1",
            text: "Ваш авто готов. Администратор подтвердил завершение услуги. Можете забирать ключи.",
            date: Calendar.current.date(byAdding: .minute, value: -5, to: Date()) ?? Date(),
            isFromService: true,
            title: "Услуга завершена",
            source: .admin,
            isRead: false
        ),
        ServiceChatMessage(
            id: "n2",
            text: "Напоминаем: запись на химчистку салона завтра в 10:00. Подъезжайте за 5 минут.",
            date: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            isFromService: true,
            title: "Напоминание о записи",
            source: .service,
            isRead: true
        ),
        ServiceChatMessage(
            id: "n3",
            text: "Запись на мойку кузова подтверждена. Ждём вас 3 февраля в 18:00.",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            isFromService: true,
            title: "Запись подтверждена",
            source: .admin,
            isRead: true
        ),
    ]
}
