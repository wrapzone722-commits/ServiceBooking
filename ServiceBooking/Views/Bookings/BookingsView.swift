//
//  BookingsView.swift
//  ServiceBooking
//
//  Страница записей
//  Стиль iOS — светлая и тёмная темы
//

import SwiftUI

struct BookingsView: View {
    @EnvironmentObject var viewModel: BookingsViewModel
    @EnvironmentObject var appRouter: AppRouter
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var selectedSegment = 0
    @State private var showCancelAlert = false
    @State private var bookingToCancel: Booking?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    segmentPicker
                    content
                }
                
                if !networkMonitor.isConnected {
                    VStack {
                        NoConnectionBanner()
                            .padding(.top, 8)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Мои записи")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await viewModel.loadBookings() }
            .onAppear { Task { await viewModel.loadBookings() } }
            .alert("Отменить запись?", isPresented: $showCancelAlert, presenting: bookingToCancel) { booking in
                Button("Отменить запись", role: .destructive) {
                    Task { await viewModel.cancelBooking(booking) }
                }
                Button("Назад", role: .cancel) {}
            } message: { booking in
                Text("Вы уверены, что хотите отменить запись на \(booking.serviceName)?")
            }
        }
    }
    
    private var segmentPicker: some View {
        Picker("Записи", selection: $selectedSegment) {
            Text("Предстоящие").tag(0)
            Text("Прошедшие").tag(1)
            Text("Отмененные").tag(2)
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.bookings.isEmpty {
            LoadingView(message: "Загрузка записей...")
        } else if let error = viewModel.errorMessage, viewModel.bookings.isEmpty {
            ErrorView(message: error, retryAction: { await viewModel.loadBookings() }, onUseDemoFallback: {
                ConsoleConfigStorage.shared.reset()
                APIConfig.useMockData = true
                Task { await viewModel.loadBookings() }
            }, onDismiss: {
                viewModel.clearError()
                appRouter.returnToQRScan()
            })
        } else if currentBookings.isEmpty {
            EmptyStateView(icon: emptyStateIcon, title: emptyStateTitle, subtitle: emptyStateSubtitle)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(currentBookings) { booking in
                        BookingCard(booking: booking) {
                            bookingToCancel = booking
                            showCancelAlert = true
                        }
                    }
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
        }
    }
    
    private var currentBookings: [Booking] {
        switch selectedSegment {
        case 0: return viewModel.upcomingBookings
        case 1: return viewModel.pastBookings
        case 2: return viewModel.cancelledBookings
        default: return []
        }
    }
    
    private var emptyStateIcon: String {
        switch selectedSegment {
        case 0: return "calendar.badge.plus"
        case 1: return "clock.arrow.circlepath"
        case 2: return "xmark.circle"
        default: return "calendar"
        }
    }
    
    private var emptyStateTitle: String {
        switch selectedSegment {
        case 0: return "Нет предстоящих записей"
        case 1: return "Нет прошедших записей"
        case 2: return "Нет отмененных записей"
        default: return "Нет записей"
        }
    }
    
    private var emptyStateSubtitle: String {
        switch selectedSegment {
        case 0: return "Запишитесь на услугу на главной странице"
        case 1: return "Здесь будут завершенные записи"
        case 2: return "Здесь будут отмененные записи"
        default: return ""
        }
    }
}

// MARK: - Booking Card

struct BookingCard: View {
    let booking: Booking
    var onCancel: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(booking.serviceName)
                    .font(.headline)
                    .foregroundStyle(AppTheme.label)
                Spacer()
                StatusBadge(status: booking.status)
            }
            
            HStack(spacing: 16) {
                Label(booking.formattedDate, systemImage: "calendar")
                Label(booking.formattedTime, systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundStyle(AppTheme.secondaryLabel)
            
            HStack {
                Text(booking.formattedPrice)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                
                Spacer()
                
                if booking.canCancel, let onCancel = onCancel {
                    Button("Отменить") { onCancel() }
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.destructive)
                }
            }
            
            if let notes = booking.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryLabel)
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: BookingStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusBackgroundColor)
            .foregroundStyle(statusForegroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    private var statusBackgroundColor: Color {
        switch status {
        case .pending: return Color(.systemOrange).opacity(0.2)
        case .confirmed: return Color.accentColor.opacity(0.2)
        case .inProgress: return Color(.systemPurple).opacity(0.2)
        case .completed: return Color(.systemGreen).opacity(0.2)
        case .cancelled: return Color(.systemRed).opacity(0.2)
        }
    }
    
    private var statusForegroundColor: Color {
        switch status {
        case .pending: return Color(.systemOrange)
        case .confirmed: return Color.accentColor
        case .inProgress: return Color(.systemPurple)
        case .completed: return Color(.systemGreen)
        case .cancelled: return Color(.systemRed)
        }
    }
}

#Preview {
    BookingsView()
        .environmentObject(BookingsViewModel())
        .environmentObject(AppRouter())
}
