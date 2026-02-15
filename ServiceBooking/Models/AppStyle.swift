//
//  AppStyle.swift
//  ServiceBooking
//
//  Настройки внешнего вида: акцентный цвет и интенсивность градиентов
//

import SwiftUI

/// Пресет акцентного цвета
enum AccentPreset: String, CaseIterable, Identifiable {
    case blue = "blue"
    case teal = "teal"
    case purple = "purple"
    case coral = "coral"
    case mint = "mint"
    case amber = "amber"
    case rose = "rose"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .blue: return Color(red: 0.2, green: 0.44, blue: 0.98)
        case .teal: return Color(red: 0.2, green: 0.78, blue: 0.74)
        case .purple: return Color(red: 0.69, green: 0.4, blue: 0.98)
        case .coral: return Color(red: 1.0, green: 0.45, blue: 0.42)
        case .mint: return Color(red: 0.4, green: 0.9, blue: 0.68)
        case .amber: return Color(red: 1.0, green: 0.7, blue: 0.25)
        case .rose: return Color(red: 0.98, green: 0.4, blue: 0.52)
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .blue: return [Color(red: 0.2, green: 0.44, blue: 0.98), Color(red: 0.4, green: 0.6, blue: 1.0)]
        case .teal: return [Color(red: 0.2, green: 0.78, blue: 0.74), Color(red: 0.3, green: 0.85, blue: 0.95)]
        case .purple: return [Color(red: 0.69, green: 0.4, blue: 0.98), Color(red: 0.85, green: 0.5, blue: 1.0)]
        case .coral: return [Color(red: 1.0, green: 0.45, blue: 0.42), Color(red: 1.0, green: 0.6, blue: 0.5)]
        case .mint: return [Color(red: 0.4, green: 0.9, blue: 0.68), Color(red: 0.5, green: 0.95, blue: 0.8)]
        case .amber: return [Color(red: 1.0, green: 0.7, blue: 0.25), Color(red: 1.0, green: 0.85, blue: 0.5)]
        case .rose: return [Color(red: 0.98, green: 0.4, blue: 0.52), Color(red: 1.0, green: 0.6, blue: 0.7)]
        }
    }
    
    var iconName: String {
        switch self {
        case .blue: return "drop.fill"
        case .teal: return "leaf.fill"
        case .purple: return "sparkles"
        case .coral: return "flame.fill"
        case .mint: return "leaf.circle.fill"
        case .amber: return "sun.max.fill"
        case .rose: return "heart.fill"
        }
    }
}

/// Тема приложения: системная, светлая (белая), тёмная
enum AppColorScheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "Системная"
        case .light: return "Светлая (белая)"
        case .dark: return "Тёмная"
        }
    }
    
    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Интенсивность градиентов в интерфейсе
enum GradientStyle: String, CaseIterable, Identifiable {
    case minimal = "minimal"
    case subtle = "subtle"
    case vivid = "vivid"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .minimal: return "Минимально"
        case .subtle: return "Мягко"
        case .vivid: return "Ярко"
        }
    }
    
    var opacity: Double {
        switch self {
        case .minimal: return 0.15
        case .subtle: return 0.35
        case .vivid: return 0.6
        }
    }
}

/// Ключи для сохранения настроек
enum AppStyleKeys {
    static let accentPreset = "app_style_accent_preset"
    static let gradientStyle = "app_style_gradient_style"
    static let colorScheme = "app_style_color_scheme"
}
