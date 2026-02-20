//
//  QRScanOnboardingView.swift
//  ServiceBooking
//
//  Единоразовый экран сканирования QR при первом запуске
//

import SwiftUI

struct QRScanOnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var showScanner = false
    @State private var showManualEntry = false
    @State private var manualURL = ""
    @State private var scanError: String?
    @State private var isRegistering = false
    
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.accentColor)
                
                VStack(spacing: 12) {
                    Text("Подключение к сервису")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(isSimulator
                         ? "В симуляторе камера недоступна. Введите URL API вручную для подключения к веб-консоли."
                         : "Отсканируйте QR-код из веб-консоли администратора, чтобы подключить приложение и получить доступ к услугам.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                }
                
                if isRegistering {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Регистрация устройства...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                
                if let error = scanError {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                if isSimulator {
                    Button {
                        scanError = nil
                        showManualEntry = true
                    } label: {
                        Label("Ввести другой URL", systemImage: "link")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal, 32)
                } else {
                    Button {
                        scanError = nil
                        showScanner = true
                    } label: {
                        Label("Сканировать QR-код", systemImage: "camera.viewfinder")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 32)
                    
                    Button {
                        scanError = nil
                        showManualEntry = true
                    } label: {
                        Label("Ввести URL вручную", systemImage: "link")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal, 32)
                }
                
                Spacer()
            }
        }
        .allowsHitTesting(!isRegistering)
        .overlay {
            if isRegistering && !showManualEntry {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            QRScannerView(isPresented: $showScanner, onScan: { code in
                handleScannedCode(code)
            }, onManualEntry: {
                showScanner = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showManualEntry = true
                }
            })
        }
        .sheet(isPresented: $showManualEntry) {
            NavigationStack {
                VStack(spacing: 20) {
                    TextField("https://your-console.com/api/v1", text: $manualURL)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    Text("Введите базовый URL API веб-консоли. Будет создан уникальный ключ для профиля клиента.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if isRegistering {
                        ProgressView("Регистрация...")
                            .padding()
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("URL API")
                .allowsHitTesting(!isRegistering)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") { showManualEntry = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Подключить") {
                            if !manualURL.isEmpty {
                                handleScannedCode(manualURL)
                                if QRCodeParser.parse(manualURL)?.token != nil {
                                    showManualEntry = false
                                }
                            }
                        }
                        .disabled(manualURL.isEmpty || isRegistering)
                    }
                }
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        guard let result = QRCodeParser.parse(code) else {
            scanError = "Неверный URL. Введите корректный адрес API (например, https://api.example.com/v1)."
            return
        }
        
        if let token = result.token, !token.isEmpty {
            // QR содержал токен — сохраняем и подключаемся
            ConsoleConfigStorage.shared.save(baseURL: result.baseURL, token: token)
            isCompleted = true
            return
        }
        
        // Токена нет — регистрируем клиента и получаем уникальный API-ключ
        isRegistering = true
        scanError = nil
        Task {
            await registerAndConnect(baseURL: result.baseURL)
        }
    }
    
    /// Регистрация в веб-консоли и получение уникального API-ключа
    private func registerAndConnect(baseURL: String) async {
        do {
            let response = try await ClientRegistry.register(baseURL: baseURL)
            await MainActor.run {
                ConsoleConfigStorage.shared.save(baseURL: baseURL, token: response.apiKey)
                scanError = nil
                isRegistering = false
                showManualEntry = false
                isCompleted = true
            }
        } catch {
            await MainActor.run {
                scanError = "Не удалось зарегистрироваться: \(error.localizedDescription). Убедитесь, что веб-консоль доступна."
                isRegistering = false
            }
        }
    }
    
}
