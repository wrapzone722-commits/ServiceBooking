//
//  ContentView.swift
//  ServiceBooking
//
//  Главный экран с Tab навигацией
//  Градиенты и настраиваемый акцентный цвет
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var bookingsViewModel: BookingsViewModel
    @EnvironmentObject private var activityManager: ServiceExecutionActivityManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Услуги")
                }
                .tag(0)
            
            BookingsView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Мои записи")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профиль")
                }
                .tag(2)
        }
        .tint(AppTheme.accent)
        .toolbarBackground(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    AppTheme.accentPreset.gradientColors[0].opacity(AppTheme.gradientStyle.opacity * 0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            for: .tabBar
        )
        .onAppear {
            Task {
                await bookingsViewModel.loadBookings()
                await startLiveActivityIfInProgress()
            }
        }
    }
    
    /// Автозапуск Live Activity, если у пользователя есть запись в статусе «В процессе» (администратор подтвердил в консоли).
    private func startLiveActivityIfInProgress() async {
        guard let inProgress = bookingsViewModel.bookings.first(where: { $0.status == .inProgress }) else { return }
        if activityManager.currentActivity?.attributes.bookingId == inProgress.id { return }
        let startTime = inProgress.inProgressStartedAt ?? inProgress.dateTime
        await activityManager.startActivity(for: inProgress, startTime: startTime)
    }
}

#Preview {
    ContentView()
        .environmentObject(ServicesViewModel())
        .environmentObject(BookingsViewModel())
        .environmentObject(ProfileViewModel())
        .environmentObject(AppRouter())
        .environmentObject(ServiceExecutionActivityManager())
        .environmentObject(AppStyleManager.shared)
}
