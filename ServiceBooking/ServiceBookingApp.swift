//
//  ServiceBookingApp.swift
//  ServiceBooking
//
//  iOS приложение для записи на услуги
//
//  Flow запуска:
//  1. Splash
//  2. QR-скан (единоразово, если нет конфигурации)
//  3. Основное приложение
//

import SwiftUI

@main
struct ServiceBookingApp: App {
    @StateObject private var servicesViewModel = ServicesViewModel()
    @StateObject private var bookingsViewModel = BookingsViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var appRouter = AppRouter()
    @StateObject private var activityManager = ServiceExecutionActivityManager()
    @StateObject private var appStyleManager = AppStyleManager.shared
    
    @State private var splashFinished = false
    @State private var qrScanCompleted = ConsoleConfigStorage.shared.hasConfig

    var body: some Scene {
        WindowGroup {
            ZStack {
                if splashFinished && qrScanCompleted {
                    ContentView()
                        .environmentObject(servicesViewModel)
                        .environmentObject(bookingsViewModel)
                        .environmentObject(profileViewModel)
                        .environmentObject(appRouter)
                        .environmentObject(activityManager)
                        .environmentObject(appStyleManager)
                        .transition(.opacity)
                }
                
                if splashFinished && !qrScanCompleted {
                    QRScanOnboardingView(isCompleted: $qrScanCompleted)
                        .transition(.opacity)
                }
                
                if !splashFinished {
                    SplashView(isFinished: $splashFinished)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: splashFinished)
            .animation(.easeInOut(duration: 0.3), value: qrScanCompleted)
            .onAppear {
                appRouter.onReturnToQRScan = {
                    qrScanCompleted = false
                }
            }
            .preferredColorScheme(appStyleManager.preferredColorScheme)
        }
    }
}
