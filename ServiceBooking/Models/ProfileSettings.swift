//
//  ProfileSettings.swift
//  ServiceBooking
//
//  Локальные настройки профиля (уведомления, напоминания, способ связи)
//

import Foundation

/// За сколько до записи напоминать
enum ReminderTiming: String, CaseIterable, Identifiable {
    case m15 = "15m"
    case h1 = "1h"
    case d1 = "1d"
    case d1h1 = "1d1h"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .m15: return "За 15 мин"
        case .h1: return "За 1 час"
        case .d1: return "За 1 день"
        case .d1h1: return "За 1 день и 1 час"
        }
    }
}

/// Предпочитаемый способ связи
enum PreferredContact: String, CaseIterable, Identifiable {
    case any = "any"
    case telegram = "telegram"
    case email = "email"
    case phone = "phone"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .any: return "Без предпочтений"
        case .telegram: return "Telegram"
        case .email: return "Email"
        case .phone: return "Телефон"
        }
    }
}

enum ProfileSettingsKeys {
    static let pushEnabled = "profile_push_notifications_enabled"
    static let reminderTiming = "profile_reminder_timing"
    static let preferredContact = "profile_preferred_contact"
}
