//
//  ServiceDetailView.swift
//  ServiceBooking
//
//  Детальная страница услуги
//  Стиль iOS — светлая и тёмная темы
//

import SwiftUI

struct ServiceDetailView: View {
    let service: Service
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bookingsViewModel: BookingsViewModel
    @State private var showBookingSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    
                    infoSection
                    
                    descriptionSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("Детали услуги")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { bookButton }
            .sheet(isPresented: $showBookingSheet) {
                BookingCreationView(service: service)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(service.category)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            Text(service.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.label)
            
            HStack(spacing: 20) {
                Label(service.formattedPrice, systemImage: "rublesign.circle.fill")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                
                Label(service.formattedDuration, systemImage: "clock.fill")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryLabel)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }
    
    private var infoSection: some View {
        VStack(spacing: 0) {
            InfoRow(icon: "clock", title: "Длительность", value: service.formattedDuration)
            Divider()
                .padding(.leading, 44)
            InfoRow(icon: "rublesign.circle", title: "Стоимость", value: service.formattedPrice)
            Divider()
                .padding(.leading, 44)
            InfoRow(icon: "folder", title: "Категория", value: service.category)
        }
        .padding()
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Описание")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.label)
            
            Text(service.description)
                .font(.body)
                .foregroundStyle(AppTheme.secondaryLabel)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }
    
    private var bookButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                showBookingSheet = true
            } label: {
                HStack {
                    Text("Записаться")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(service.formattedPrice)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .background(AppTheme.secondaryBackground)
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
            
            Text(title)
                .foregroundStyle(AppTheme.secondaryLabel)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.label)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ServiceDetailView(service: Service(
        id: "preview_service",
        name: "Химчистка салона",
        description: "Полная химчистка салона автомобиля",
        price: 5000,
        duration: 180,
        category: "Автоуслуги",
        imageURL: nil,
        isActive: true
    ))
        .environmentObject(BookingsViewModel())
}
