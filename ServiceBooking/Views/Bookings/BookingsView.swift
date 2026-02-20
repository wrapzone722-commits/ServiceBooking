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
    @EnvironmentObject var activityManager: ServiceExecutionActivityManager
    @ObservedObject private var styleManager = AppStyleManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var selectedSegment = 0
    @State private var showCancelAlert = false
    @State private var bookingToCancel: Booking?
    @State private var selectedBooking: Booking?
    @State private var actPDFItem: ActPDFItem?
    @State private var actError: String?
    @State private var actLoadingBookingId: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                styleManager.screenGradient(base: AppTheme.background)
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
            .refreshable {
                await viewModel.loadBookings(silentRefresh: true)
                if let b = viewModel.bookings.first(where: { $0.status == .inProgress }),
                   activityManager.currentActivity?.attributes.bookingId != b.id {
                    let startTime = b.inProgressStartedAt ?? b.dateTime
                    await activityManager.startActivity(for: b, startTime: startTime)
                }
            }
            .onAppear { Task { await viewModel.loadBookings() } }
            .alert("Отменить запись?", isPresented: $showCancelAlert, presenting: bookingToCancel) { booking in
                Button("Отменить запись", role: .destructive) {
                    Task { await viewModel.cancelBooking(booking) }
                }
                Button("Назад", role: .cancel) {}
            } message: { booking in
                Text("Вы уверены, что хотите отменить запись на \(booking.serviceName)?")
            }
            .fullScreenCover(item: $selectedBooking) { booking in
                ServiceExecutionLiveActivityView(booking: booking)
            }
            .sheet(item: $actPDFItem) { item in
                ActPDFView(url: item.url) {
                    actPDFItem = nil
                    try? FileManager.default.removeItem(at: item.url)
                }
            }
            .alert("Ошибка загрузки акта", isPresented: .init(
                get: { actError != nil },
                set: { if !$0 { actError = nil } }
            )) {
                Button("OK") { actError = nil }
            } message: {
                Text(actError ?? "")
            }
        }
    }
    
    private func openAct(for booking: Booking) {
        guard booking.status == .completed else { return }
        actLoadingBookingId = booking.id
        actError = nil
        Task {
            do {
                let data = try await APIService.shared.fetchBookingAct(bookingId: booking.id)
                let temp = FileManager.default.temporaryDirectory
                    .appendingPathComponent("akt-\(booking.id).pdf")
                try data.write(to: temp)
                await MainActor.run {
                    actPDFItem = ActPDFItem(url: temp)
                    actLoadingBookingId = nil
                }
            } catch {
                await MainActor.run {
                    actError = error.localizedDescription
                    actLoadingBookingId = nil
                }
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
            ErrorView(message: error, retryAction: { await viewModel.loadBookings() }, onDismiss: {
                viewModel.clearError()
                appRouter.returnToQRScan()
            })
        } else if currentBookings.isEmpty {
            EmptyStateView(icon: emptyStateIcon, title: emptyStateTitle, subtitle: emptyStateSubtitle)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(currentBookings) { booking in
                        BookingCard(
                            booking: booking,
                            onCancel: {
                                bookingToCancel = booking
                                showCancelAlert = true
                            },
                            onOpenAct: booking.status == .completed ? { openAct(for: booking) } : nil,
                            actLoading: actLoadingBookingId == booking.id
                        )
                        .onTapGesture {
                            if booking.status == .inProgress {
                                selectedBooking = booking
                            }
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

private struct ActPDFItem: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - Booking Card

struct BookingCard: View {
    let booking: Booking
    var onCancel: (() -> Void)?
    var onOpenAct: (() -> Void)?
    var actLoading: Bool = false
    
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
                
                if booking.status == .inProgress {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                            .font(.subheadline)
                        Text("Смотреть процесс")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color.cyan)
                } else if booking.status == .completed, let onOpenAct = onOpenAct {
                    Button {
                        onOpenAct()
                    } label: {
                        if actLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Label("Акт", systemImage: "doc.text")
                                .font(.subheadline)
                        }
                    }
                    .disabled(actLoading)
                } else if booking.canCancel, let onCancel = onCancel {
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
        .background(
            booking.status == .inProgress
                ? AnyView(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.1),
                            Color.blue.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                : AnyView(AppTheme.secondaryBackground)
        )
        .overlay(
            booking.status == .inProgress
                ? RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1.5)
                : nil
        )
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
        .environmentObject(ServiceExecutionActivityManager())
}
