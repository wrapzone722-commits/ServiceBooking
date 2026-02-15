//
//  MyContactsView.swift
//  ServiceBooking
//
//  Экран "Мои контакты"
//

import SwiftUI

struct MyContactsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Описание
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ваши контакты")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Здесь отображаются все ваши контактные данные, которые используются для связи с вами.")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .padding(.horizontal)
                    
                    // Список контактов
                    VStack(spacing: 16) {
                        contactCard(
                            icon: "paperplane.fill",
                            title: "Telegram",
                            subtitle: "Основной способ связи",
                            color: .blue
                        )
                        
                        contactCard(
                            icon: "person.2.fill",
                            title: "VK",
                            subtitle: "Социальная сеть",
                            color: .blue
                        )
                        
                        contactCard(
                            icon: "envelope.fill",
                            title: "Email",
                            subtitle: "Электронная почта",
                            color: .gray
                        )
                        
                        contactCard(
                            icon: "phone.fill",
                            title: "Телефон",
                            subtitle: "Номер телефона",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Мои контакты")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
    
    private func contactCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.label))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    MyContactsView()
}
