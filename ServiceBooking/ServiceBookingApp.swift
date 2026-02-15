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
    
    // РФ: 152‑ФЗ / 242‑ФЗ — фиксируем факт принятия документов (шаблон).
    private let requiredLegalVersion = "2026-02-15"
    @AppStorage("sb_ios_legal_version") private var legalVersion: String = ""
    @AppStorage("sb_ios_legal_accepted_at") private var legalAcceptedAt: String = ""
    private var legalAccepted: Bool { legalVersion == requiredLegalVersion && !legalAcceptedAt.isEmpty }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if splashFinished && qrScanCompleted && legalAccepted {
                    ContentView()
                        .environmentObject(servicesViewModel)
                        .environmentObject(bookingsViewModel)
                        .environmentObject(profileViewModel)
                        .environmentObject(appRouter)
                        .environmentObject(activityManager)
                        .environmentObject(appStyleManager)
                        .transition(.opacity)
                }
                
                if splashFinished && qrScanCompleted && !legalAccepted {
                    LegalConsentView(requiredVersion: requiredLegalVersion, allowDismiss: false)
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

struct LegalConsentView: View {
    let requiredVersion: String
    let allowDismiss: Bool
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("sb_ios_legal_version") private var legalVersion: String = ""
    @AppStorage("sb_ios_legal_accepted_at") private var legalAcceptedAt: String = ""
    
    private var accepted: Bool { legalVersion == requiredVersion && !legalAcceptedAt.isEmpty }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Документы и персональные данные")
                        .font(.largeTitle.bold())
                    
                    Text("Для использования приложения нужно принять документы (152‑ФЗ/242‑ФЗ).")
                        .foregroundStyle(.secondary)
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            NavigationLink("Политика обработки ПДн") {
                                LegalTextView(
                                    title: "Политика обработки персональных данных",
                                    text:
                                        """
                                        Шаблон политики во исполнение №152‑ФЗ «О персональных данных» и требований локализации (№242‑ФЗ) при применимости.
                                        
                                        Оператор: <указать организацию/ИП, ИНН/ОГРН, адрес, контакты>.
                                        
                                        Цели: предоставление сервиса записи, управление записями, уведомления, поддержка, улучшение качества.
                                        
                                        Состав данных: имя, контакты (если указаны), данные записей, технические идентификаторы устройства; данные Telegram — при авторизации через Telegram (если используется).
                                        
                                        Права субъекта: запрос сведений, уточнение, блокирование, удаление, отзыв согласия — по контактам оператора.
                                        """
                                )
                            }
                            NavigationLink("Согласие на обработку ПДн") {
                                LegalTextView(
                                    title: "Согласие на обработку персональных данных",
                                    text:
                                        """
                                        Нажимая «Принять», я даю согласие Оператору на обработку моих персональных данных в целях работы приложения (вход, запись на услуги, уведомления, поддержка) в соответствии с №152‑ФЗ.
                                        
                                        Согласие может быть отозвано в разделе «Профиль» (или обращением к Оператору).
                                        """
                                )
                            }
                            NavigationLink("Пользовательское соглашение") {
                                LegalTextView(
                                    title: "Пользовательское соглашение",
                                    text:
                                        """
                                        Приложение предоставляет возможность записаться на услуги и управлять своими записями.
                                        Пользователь обязуется предоставлять достоверные данные и не нарушать права третьих лиц.
                                        
                                        Оператор может обновлять документы; при изменении версии потребуется повторное принятие.
                                        """
                                )
                            }
                        }
                    }
                    
                    if accepted {
                        Text("Принято: \(legalAcceptedAt)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        legalVersion = requiredVersion
                        legalAcceptedAt = ISO8601DateFormatter().string(from: Date())
                        if allowDismiss { dismiss() }
                    } label: {
                        Text("Принять")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text("Это шаблон. Для релиза по РФ заполните реквизиты оператора и уточните состав/цели/сроки хранения.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if allowDismiss {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Закрыть") { dismiss() }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Text("v\(requiredVersion)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct LegalTextView: View {
    let title: String
    let text: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.title2.bold())
                Text(text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
