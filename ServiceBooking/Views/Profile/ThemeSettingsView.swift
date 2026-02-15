//
//  ThemeSettingsView.swift
//  ServiceBooking
//
//  Настройки оформления: акцентный цвет и интенсивность градиентов
//

import SwiftUI

struct ThemeSettingsView: View {
    @ObservedObject private var styleManager = AppStyleManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                styleManager.screenGradient()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        themeSection
                        accentSection
                        gradientSection
                        previewSection
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Оформление")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
    
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Тема")
            
            VStack(spacing: 10) {
                ForEach(AppColorScheme.allCases) { scheme in
                    Button {
                        styleManager.colorScheme = scheme
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: scheme.iconName)
                                .font(.system(size: 20))
                                .foregroundStyle(scheme == .light ? Color.orange : (scheme == .dark ? Color.indigo : Color.gray))
                                .frame(width: 28, alignment: .center)
                            Text(scheme.displayName)
                                .font(.body)
                                .foregroundStyle(Color(.label))
                            Spacer()
                            if styleManager.colorScheme == scheme {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(styleManager.colorScheme == scheme ? AppTheme.accent.opacity(0.12) : Color(.tertiarySystemFill))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private var accentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Акцентный цвет")
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 56))], spacing: 16) {
                ForEach(AccentPreset.allCases) { preset in
                    accentButton(preset)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private func accentButton(_ preset: AccentPreset) -> some View {
        let isSelected = styleManager.accentPreset == preset
        return Button {
            styleManager.accentPreset = preset
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: preset.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: preset.iconName)
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var gradientSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Интенсивность градиентов")
            
            VStack(spacing: 12) {
                ForEach(GradientStyle.allCases) { style in
                    gradientRow(style)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private func gradientRow(_ style: GradientStyle) -> some View {
        let isSelected = styleManager.gradientStyle == style
        return Button {
            styleManager.gradientStyle = style
        } label: {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: styleManager.accentPreset.gradientColors.map { $0.opacity(style.opacity) },
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 48, height: 36)
                
                Text(style.displayName)
                    .font(.body)
                    .foregroundStyle(Color(.label))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? AppTheme.accent.opacity(0.12) : Color(.tertiarySystemFill))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Предпросмотр")
            
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(styleManager.cardGradient())
                    .overlay {
                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.accent)
                                .frame(width: 40, height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.tertiaryLabel))
                                .frame(width: 80, height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.tertiaryLabel).opacity(0.6))
                                .frame(width: 60, height: 6)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 100)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(styleManager.cardGradient())
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .frame(height: 100)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(Color(.secondaryLabel))
    }
}

#Preview {
    ThemeSettingsView()
}
