//
//  NetworkStatusView.swift
//  ServiceBooking
//
//  Компоненты статуса сети
//  Стиль iOS — светлая и тёмная темы
//

import SwiftUI

/// Баннер отсутствия интернета
struct NoConnectionBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.subheadline)
            Text("Нет подключения к интернету")
                .font(.subheadline)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.destructive)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Сообщение об ошибке
struct ErrorView: View {
    let message: String
    let retryAction: () async -> Void
    var onUseDemoFallback: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.warning)
            
            Text("Ошибка загрузки")
                .font(.headline)
                .foregroundStyle(AppTheme.label)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                Task { await retryAction() }
            } label: {
                Label("Повторить", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            
            if let onUseDemoFallback = onUseDemoFallback {
                Button {
                    onUseDemoFallback()
                } label: {
                    Text("Использовать демо-режим")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let onDismiss = onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Label("Назад", systemImage: "chevron.left")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Индикатор загрузки
struct LoadingView: View {
    var message: String = "Загрузка..."
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryLabel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Пустое состояние
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.tertiaryLabel)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.label)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
