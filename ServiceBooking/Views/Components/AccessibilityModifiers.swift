//
//  AccessibilityModifiers.swift
//  ServiceBooking
//
//  Модификаторы для доступности (Accessibility)
//  Требование Apple App Store Review Guidelines 2.5.5
//

import SwiftUI

// MARK: - Accessibility Labels

extension View {
    /// Добавляет accessibility метки для VoiceOver
    func accessibleService(name: String, price: String, duration: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(name), цена \(price), длительность \(duration)")
            .accessibilityHint("Нажмите дважды для записи на услугу")
    }
    
    /// Accessibility для карточки записи
    func accessibleBooking(service: String, date: String, time: String, status: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Запись на \(service), \(date) в \(time), статус: \(status)")
    }
    
    /// Accessibility для кнопки
    func accessibleButton(_ label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Dynamic Type Support

struct ScaledFont: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    var style: Font.TextStyle
    
    func body(content: Content) -> some View {
        content
            .font(.system(style))
            .lineLimit(nil)
            .minimumScaleFactor(0.7)
    }
}

extension View {
    /// Поддержка Dynamic Type (масштабируемый текст)
    func scaledFont(_ style: Font.TextStyle) -> some View {
        modifier(ScaledFont(style: style))
    }
}

// MARK: - Reduce Motion Support

struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? .none : .default, value: UUID())
    }
}

extension View {
    /// Уважает настройку "Уменьшение движения"
    func respectReduceMotion() -> some View {
        modifier(ReduceMotionModifier())
    }
}

// MARK: - High Contrast Support

struct HighContrastModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) var contrast
    let normalColor: Color
    let highContrastColor: Color
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(contrast == .increased ? highContrastColor : normalColor)
    }
}

extension View {
    /// Поддержка высокой контрастности
    func adaptiveColor(normal: Color, highContrast: Color) -> some View {
        modifier(HighContrastModifier(normalColor: normal, highContrastColor: highContrast))
    }
}
