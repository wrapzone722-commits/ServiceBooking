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
    @State private var company: CompanyInfo?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Документы и персональные данные")
                        .font(.largeTitle.bold())
                    
                    Text("Для использования приложения нужно принять документы (152‑ФЗ/242‑ФЗ).")
                        .foregroundStyle(.secondary)
                    
                    if let c = company {
                        Text("Оператор: \(operatorLine(c))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            NavigationLink("Политика обработки ПДн") {
                                LegalTextView(
                                    title: "Политика обработки персональных данных",
                                    text:
                                        """
                                        Политика определяет порядок и условия обработки персональных данных пользователей сервиса в соответствии с Федеральным законом РФ №152‑ФЗ «О персональных данных» (а также требованиями локализации №242‑ФЗ — при применимости).
                                        
                                        Оператор — организация/ИП, реквизиты и контакты которого указаны в разделе «О компании».
                                        
                                        Цели обработки: предоставление сервиса записи и управления записями, коммуникация и уведомления, поддержка, обеспечение безопасности и улучшение качества сервиса.
                                        
                                        Категории данных: имя, контактные данные (телефон/e‑mail — если указаны), данные о записях (дата/время/услуга/пост), комментарии, технические идентификаторы устройства; данные Telegram — при входе через Telegram.
                                        
                                        Права субъекта: получение сведений, уточнение, блокирование, удаление, отзыв согласия (если применимо). Обращения направляются оператору по контактам.
                                        """
                                )
                            }
                            NavigationLink("Согласие на обработку ПДн") {
                                LegalTextView(
                                    title: "Согласие на обработку персональных данных",
                                    text:
                                        """
                                        Нажимая «Принять», я выражаю согласие Оператору на обработку моих персональных данных в целях предоставления сервиса записи и управления записями, включая сбор, запись, систематизацию, хранение, уточнение, использование, обезличивание, блокирование и удаление, в соответствии с №152‑ФЗ.
                                        
                                        Согласие может быть отозвано в любой момент: через обращение к Оператору по контактам, указанным в разделе «О компании», а также путём удаления приложения (если применимо).
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
            .task {
                do { company = try await APIService.shared.fetchCompany() } catch { company = nil }
            }
        }
    }
}

private func operatorLine(_ c: CompanyInfo) -> String {
    var parts: [String] = []
    if let inn = c.inn, !inn.isEmpty { parts.append("ИНН \(inn)") }
    if let ogrn = c.ogrn, !ogrn.isEmpty { parts.append("ОГРН/ОГРНИП \(ogrn)") }
    let head = c.name + (parts.isEmpty ? "" : " (" + parts.joined(separator: ", ") + ")")
    let contacts = [c.phone, c.email].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    let addr = (c.legalAddress?.isEmpty == false ? c.legalAddress : c.address) ?? ""
    let tail = [addr, contacts].filter { !$0.isEmpty }.joined(separator: " • ")
    return tail.isEmpty ? head : "\(head) — \(tail)"
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
