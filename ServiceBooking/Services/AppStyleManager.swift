//
//  AppStyleManager.swift
//  ServiceBooking
//
//  Управление темой и стилем приложения
//

import SwiftUI

@MainActor
final class AppStyleManager: ObservableObject {
    static let shared = AppStyleManager()
    
    @AppStorage(AppStyleKeys.accentPreset) var accentPresetRaw: String = AccentPreset.blue.rawValue
    @AppStorage(AppStyleKeys.gradientStyle) var gradientStyleRaw: String = GradientStyle.subtle.rawValue
    @AppStorage(AppStyleKeys.colorScheme) var colorSchemeRaw: String = AppColorScheme.system.rawValue
    
    var colorScheme: AppColorScheme {
        get { AppColorScheme(rawValue: colorSchemeRaw) ?? .system }
        set {
            colorSchemeRaw = newValue.rawValue
            objectWillChange.send()
        }
    }
    
    var accentPreset: AccentPreset {
        get { AccentPreset(rawValue: accentPresetRaw) ?? .blue }
        set {
            accentPresetRaw = newValue.rawValue
            objectWillChange.send()
        }
    }
    
    var gradientStyle: GradientStyle {
        get { GradientStyle(rawValue: gradientStyleRaw) ?? .subtle }
        set {
            gradientStyleRaw = newValue.rawValue
            objectWillChange.send()
        }
    }
    
    /// Текущий акцентный цвет
    var accentColor: Color {
        accentPreset.color
    }
    
    /// Предпочитаемая тема для .preferredColorScheme(...)
    var preferredColorScheme: ColorScheme? {
        colorScheme.preferredColorScheme
    }
    
    /// Градиент для фонов (с учётом интенсивности)
    func screenGradient(base: Color = Color(.systemGroupedBackground)) -> LinearGradient {
        let colors = accentPreset.gradientColors.map { $0.opacity(gradientStyle.opacity) }
        return LinearGradient(
            colors: [base, base.opacity(0.95), colors[0].opacity(0.3), colors[1].opacity(0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Градиент для карточек
    func cardGradient() -> LinearGradient {
        let colors = accentPreset.gradientColors
        let opacity = gradientStyle.opacity * 0.5
        return LinearGradient(
            colors: [
                Color(.secondarySystemGroupedBackground),
                colors[0].opacity(opacity),
                colors[1].opacity(opacity * 0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Градиент для TabBar / навигации
    func navGradient() -> LinearGradient {
        let colors = accentPreset.gradientColors
        return LinearGradient(
            colors: [
                Color(.systemBackground).opacity(0.95),
                colors[0].opacity(gradientStyle.opacity * 0.4),
                colors[1].opacity(gradientStyle.opacity * 0.2)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private init() {}
}
