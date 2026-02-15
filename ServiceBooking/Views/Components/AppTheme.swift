//
//  AppTheme.swift
//  ServiceBooking
//
//  Система дизайна в стиле iOS
//  Автоматическая поддержка светлой и тёмной темы
//

import SwiftUI

/// Цвета приложения — адаптируются к светлой/тёмной теме
enum AppTheme {
    
    // MARK: - Backgrounds
    
    /// Основной фон экрана
    static var background: Color {
        Color(.systemGroupedBackground)
    }
    
    /// Фон карточек и секций
    static var secondaryBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }
    
    /// Фон полей ввода, чипов
    static var tertiaryBackground: Color {
        Color(.tertiarySystemGroupedBackground)
    }
    
    /// Фон элементов (кнопки, поля)
    static var fill: Color {
        Color(.systemFill)
    }
    
    static var secondaryFill: Color {
        Color(.secondarySystemFill)
    }
    
    // MARK: - Text
    
    static var label: Color {
        Color(.label)
    }
    
    static var secondaryLabel: Color {
        Color(.secondaryLabel)
    }
    
    static var tertiaryLabel: Color {
        Color(.tertiaryLabel)
    }
    
    // MARK: - Accent (из настроек оформления, доступен из любого контекста)
    
    static var accent: Color {
        let preset = AccentPreset(rawValue: UserDefaults.standard.string(forKey: AppStyleKeys.accentPreset) ?? "") ?? .blue
        return preset.color
    }
    
    /// Акцент на светлом фоне (для тёмной темы)
    static var accentTinted: Color {
        accent.opacity(0.15)
    }

    /// Пресет акцента (из UserDefaults, для использования вне MainActor)
    static var accentPreset: AccentPreset {
        AccentPreset(rawValue: UserDefaults.standard.string(forKey: AppStyleKeys.accentPreset) ?? "") ?? .blue
    }

    /// Интенсивность градиентов (из UserDefaults)
    static var gradientStyle: GradientStyle {
        GradientStyle(rawValue: UserDefaults.standard.string(forKey: AppStyleKeys.gradientStyle) ?? "") ?? .subtle
    }
    
    // MARK: - Semantic Colors (адаптивные)
    
    static var destructive: Color {
        Color(.systemRed)
    }
    
    static var success: Color {
        Color(.systemGreen)
    }
    
    static var warning: Color {
        Color(.systemOrange)
    }
    
    // MARK: - Card Style
    
    static func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(secondaryBackground)
    }
    
    static var cardCornerRadius: CGFloat { 12 }
}

// MARK: - View Modifiers

extension View {
    /// Стиль карточки в стиле iOS
    func iosCardStyle() -> some View {
        self
            .padding()
            .background(AppTheme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }
    
    /// Стиль поля ввода
    func iosInputStyle() -> some View {
        self
            .padding()
            .background(AppTheme.tertiaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
