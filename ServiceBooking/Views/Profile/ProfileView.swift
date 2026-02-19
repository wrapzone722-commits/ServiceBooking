//
//  ProfileView.swift
//  ServiceBooking
//
//  Профиль в стиле карточки
//  Возможность загрузки фото
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @EnvironmentObject var appRouter: AppRouter
    @StateObject private var networkMonitor = NetworkMonitor.shared

    @State private var showCarPicker = false
    @State private var showServiceChat = false
    @State private var showHelpFAQ = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false
    @State private var showLegalConsent = false
    @State private var showRevokeLegalConfirm = false
    @AppStorage("profile_fill_hint_shown") private var profileFillHintShown = false
    @State private var showLogoutConfirm = false
    @State private var showMyContacts = false
    @State private var showLoyaltySystem = false
    @State private var showThemeSettings = false
    @State private var showCompany = false
    
    @ObservedObject private var styleManager = AppStyleManager.shared
    @AppStorage(ProfileSettingsKeys.pushEnabled) private var pushNotificationsEnabled = true
    
    private let requiredLegalVersion = "2026-02-15"
    @AppStorage("sb_ios_legal_version") private var legalVersion: String = ""
    @AppStorage("sb_ios_legal_accepted_at") private var legalAcceptedAt: String = ""
    private var legalAccepted: Bool { legalVersion == requiredLegalVersion && !legalAcceptedAt.isEmpty }
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var pendingPasteFromMessenger: PendingMessenger?
    
    var body: some View {
        NavigationStack {
            ZStack {
                styleManager.screenGradient(base: Color(.systemGroupedBackground))
                    .ignoresSafeArea()
                
                content
                
                if !networkMonitor.isConnected {
                    VStack {
                        NoConnectionBanner()
                            .padding(.top, 8)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if viewModel.user != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button(viewModel.isEditing ? "Готово" : "Изменить") {
                            if viewModel.isEditing {
                                Task { await viewModel.saveProfile() }
                            } else {
                                viewModel.startEditing()
                            }
                        }
                        .disabled(!networkMonitor.isConnected && viewModel.isEditing)
                    }
                }
            }
            .onAppear { Task { await viewModel.loadProfile() } }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active, let pending = pendingPasteFromMessenger else { return }
                pendingPasteFromMessenger = nil
                switch pending {
                case .telegram:
                    if let s = cleanTelegramFromClipboard(), !s.isEmpty { viewModel.editTelegram = s }
                case .vk:
                    if let s = cleanVKFromClipboard(), !s.isEmpty { viewModel.editVK = s }
                }
            }
            .sheet(isPresented: $showCarPicker) {
                CarSelectionSheet(viewModel: viewModel) {
                    showCarPicker = false
                }
                .onAppear { Task { await viewModel.loadCars() } }
            }
        }
    }
    
    private func performLogout() {
        // Сначала закрываем все модалки/алерты, затем уходим на QR-скан на следующем цикле.
        showLogoutConfirm = false
        showCarPicker = false
        showServiceChat = false
        showHelpFAQ = false
        showPrivacyPolicy = false
        showTermsOfUse = false
        showMyContacts = false
        showLoyaltySystem = false
        showThemeSettings = false
        showLegalConsent = false
        showRevokeLegalConfirm = false
        
        if viewModel.isEditing {
            viewModel.cancelEditing()
        }
        
        DispatchQueue.main.async {
            appRouter.returnToQRScan()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.user == nil {
            LoadingView(message: "Загрузка профиля...")
        } else if let error = viewModel.errorMessage, viewModel.user == nil {
            ErrorView(message: error, retryAction: { await viewModel.loadProfile() }, onUseDemoFallback: {
                ConsoleConfigStorage.shared.reset()
                APIConfig.useMockData = true
                Task { await viewModel.loadProfile() }
            }, onDismiss: {
                viewModel.clearError()
                appRouter.returnToQRScan()
            })
        } else if let user = viewModel.user {
            profileCardView(user: user)
        }
    }
    
    // MARK: - Profile Card (стиль как на референсе)
    
    private func profileCardView(user: User) -> some View {
        let completeness = user.profileCompleteness
        return ScrollView {
            VStack(spacing: 24) {
                profileHintSection(user: user, completeness: completeness)
                profileCard(user: user)
                settingsCard(user: user)
                actionsSection
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.loadProfile(silentRefresh: true) }
    }
    
    // MARK: - Режим подсказок (ненавязчивый)

    /// Секция подсказок: баннер, тонкое напоминание или отметка о полноте
    @ViewBuilder
    private func profileHintSection(user: User, completeness: ProfileCompleteness) -> some View {
        if completeness.isComplete {
            profileCompleteBadge
        } else if !profileFillHintShown {
            profileMainHintBanner(completeness: completeness, user: user, dismiss: { profileFillHintShown = true })
        } else {
            profileSlimReminder(completeness: completeness, user: user)
        }
    }

    /// Отметка «Профиль заполнен» — краткая, не навязчивая
    private var profileCompleteBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.green)
            Text("Профиль заполнен")
                .font(.caption)
                .foregroundStyle(Color(.secondaryLabel))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    /// Основной баннер: контекстная подсказка по самому важному недостающему пункту
    private func profileMainHintBanner(completeness: ProfileCompleteness, user: User, dismiss: @escaping () -> Void) -> some View {
        let primary = completeness.primarySuggestion
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: primary?.icon ?? "person.text.rectangle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 6) {
                    Text(primary != nil ? "Добавьте \(primary!.title.lowercased())" : "Заполните профиль")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(.label))
                    Text(completeness.suggestionTitle)
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            HStack(spacing: 8) {
                Button {
                    performHintAction(for: primary, user: user)
                } label: {
                    Text("Заполнить")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                Button("Позже") { dismiss() }
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    /// Тонкое напоминание (после закрытия основного баннера)
    private func profileSlimReminder(completeness: ProfileCompleteness, user: User) -> some View {
        let count = completeness.missingItems.count
        let word = count == 1 ? "пункт" : (2...4).contains(count) ? "пункта" : "пунктов"
        let text = count == 1
            ? "Добавьте \(completeness.missingItems[0].title.lowercased()) для лучшего сервиса"
            : "Заполните ещё \(count) \(word) в профиле"
        return Button {
            performHintAction(for: completeness.primarySuggestion, user: user)
        } label: {
            HStack(spacing: 10) {
                Text("\(completeness.progress)%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32, alignment: .leading)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground).opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    /// Выполнить действие по подсказке
    private func performHintAction(for item: ProfileMissingItem?, user: User) {
        guard let item = item else {
            viewModel.startEditing()
            return
        }
        switch item {
        case .name, .socialLinks:
            viewModel.startEditing()
        case .car:
            showCarPicker = true
        }
    }
    
    // Единая карточка в стиле референса: изображение сверху, контент снизу
    private func profileCard(user: User) -> some View {
        VStack(spacing: 0) {
            // Превью фото: без текста и символов, скругления 15
            profilePhotoHeader(user: user)
                .frame(maxWidth: .infinity)
                .aspectRatio(4/3, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .clipped()
            
            // Белая область контента
            VStack(alignment: .leading, spacing: 16) {
                // Имя клиента
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.isEditing {
                        TextField("Имя", text: $viewModel.editFirstName)
                            .textFieldStyle(.roundedBorder)
                        TextField("Фамилия", text: $viewModel.editLastName)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Text(user.displayNameForProfile)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(.label))
                    }
                }
                
                if user.isPhoneDisplayable {
                    Button {
                        viewModel.openSocialLink(.phone)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "phone.fill")
                                .foregroundStyle(Color.accentColor)
                            Text(user.phone)
                                .font(.body)
                                .foregroundStyle(Color(.label))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                if viewModel.isEditing {
                    VStack(spacing: 8) {
                        SocialEditRowWithAppLink(
                            icon: "paperplane.fill",
                            placeholder: "Telegram",
                            text: $viewModel.editTelegram,
                            color: .blue,
                            appURL: URL(string: "tg://"),
                            pasteTransform: { cleanTelegramFromClipboard() },
                            onOpenApp: { pendingPasteFromMessenger = .telegram }
                        )
                        SocialEditRowWithAppLink(
                            icon: "person.2.fill",
                            placeholder: "VK",
                            text: $viewModel.editVK,
                            color: .blue,
                            appURL: URL(string: "vk://"),
                            pasteTransform: { cleanVKFromClipboard() },
                            onOpenApp: { pendingPasteFromMessenger = .vk }
                        )
                        TextField("Email", text: $viewModel.editEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                } else {
                    VStack(spacing: 8) {
                        if let t = user.socialLinks?.telegram, !t.isEmpty {
                            compactLinkButton(icon: "paperplane.fill", value: t, color: .blue) { viewModel.openSocialLink(.telegram) }
                        }
                        if let v = user.socialLinks?.vk, !v.isEmpty {
                            compactLinkButton(icon: "person.2.fill", value: v, color: .blue) { viewModel.openSocialLink(.vk) }
                        }
                        if let email = user.email, !email.isEmpty {
                            compactLinkButton(icon: "envelope.fill", value: email, color: .gray) { viewModel.openSocialLink(.email) }
                        }
                    }
                }
                
                // Кнопки действий в стиле iOS
                VStack(spacing: 12) {
                    modernActionButton(
                        icon: "message.fill",
                        title: "Сообщения",
                        color: .blue
                    ) {
                        showServiceChat = true
                    }
                    
                    modernActionButton(
                        icon: "person.2.fill",
                        title: "Мои контакты",
                        color: .green
                    ) {
                        showMyContacts = true
                    }
                    
                    modernActionButton(
                        icon: "star.fill",
                        title: "Система лояльности",
                        color: .orange
                    ) {
                        showLoyaltySystem = true
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemBackground),
                                styleManager.accentPreset.gradientColors[0].opacity(styleManager.gradientStyle.opacity * 0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
        .sheet(isPresented: $showServiceChat) {
            ServiceChatView()
        }
        .alert("Выйти из аккаунта?", isPresented: $showLogoutConfirm) {
            Button("Отмена", role: .cancel) {}
            Button("Выйти", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("Вам потребуется снова отсканировать QR-код для входа.")
        }
    }
    
    // MARK: - Settings Card
    
    private func settingsCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("НАСТРОЙКИ")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.tertiaryLabel))
            
            VStack(alignment: .leading, spacing: 12) {
                modernActionButton(
                    icon: "paintbrush.fill",
                    title: "Оформление",
                    color: AppTheme.accent
                ) {
                    showThemeSettings = true
                }

                HStack {
                    Image(systemName: "bell.badge.fill")
                        .font(.body)
                        .foregroundStyle(Color.orange)
                        .frame(width: 44, height: 44, alignment: .center)
                    Toggle("Push-уведомления", isOn: $pushNotificationsEnabled)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemBackground),
                                styleManager.accentPreset.gradientColors[0].opacity(styleManager.gradientStyle.opacity * 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            
            // Справка и юридическое
            VStack(alignment: .leading, spacing: 12) {
                Text("СПРАВКА")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.tertiaryLabel))
                VStack(spacing: 12) {
                    modernActionButton(icon: "questionmark.circle.fill", title: "Помощь / FAQ", color: .blue) { showHelpFAQ = true }
                    modernActionButton(icon: "building.2.fill", title: "О компании", color: .indigo) { showCompany = true }
                    modernActionButton(
                        icon: legalAccepted ? "checkmark.shield.fill" : "exclamationmark.shield.fill",
                        title: legalAccepted ? "Согласие на ПДн: принято" : "Согласие на ПДн: не принято",
                        color: legalAccepted ? .green : .orange
                    ) { showLegalConsent = true }
                    if legalAccepted {
                        modernActionButton(icon: "xmark.shield.fill", title: "Отозвать согласие", color: .red) { showRevokeLegalConfirm = true }
                    }
                    modernActionButton(icon: "hand.raised.fill", title: "Политика конфиденциальности", color: .gray) { showPrivacyPolicy = true }
                    modernActionButton(icon: "doc.text.fill", title: "Условия использования", color: .gray) { showTermsOfUse = true }
                }
                
                HStack {
                    Text("Версия приложения")
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                    Spacer()
                    Text(appVersion)
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
        .sheet(isPresented: $showHelpFAQ) { HelpFAQView() }
        .sheet(isPresented: $showCompany) { CompanyView() }
        .sheet(isPresented: $showLegalConsent) { LegalConsentView(requiredVersion: requiredLegalVersion, allowDismiss: true) }
        .sheet(isPresented: $showPrivacyPolicy) { PrivacyPolicyView() }
        .sheet(isPresented: $showTermsOfUse) { TermsOfUseView() }
        .sheet(isPresented: $showMyContacts) { MyContactsView() }
        .sheet(isPresented: $showLoyaltySystem) { LoyaltySystemView(user: viewModel.user) }
        .sheet(isPresented: $showThemeSettings) { ThemeSettingsView() }
        .confirmationDialog("Отозвать согласие на обработку ПДн?", isPresented: $showRevokeLegalConfirm, titleVisibility: .visible) {
            Button("Отозвать", role: .destructive) {
                legalVersion = ""
                legalAcceptedAt = ""
            }
            Button("Отмена", role: .cancel) {}
        }
    }
    
    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? short : "\(short) (\(build))"
    }
    
    // Превью фото автомобиля: тап открывает выбор типа авто из папок веб-консоли
    private func profilePhotoHeader(user: User) -> some View {
        profilePhotoView(user: user)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "car.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
                    .padding(8)
            }
            .onTapGesture {
                showCarPicker = true
            }
    }
    
    private func compactLinkButton(icon: String, value: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(value)
                    .font(.body)
                    .foregroundStyle(Color(.label))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func modernActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(.label))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func placeholderRow(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color(.tertiaryLabel))
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    
    
    @ViewBuilder
    private func profilePhotoView(user: User) -> some View {
        let hasCar = (viewModel.displayedCarId ?? user.selectedCarId) != nil
        if hasCar {
            carPhotoView(user: user)
        } else {
            emptyPhotoPlaceholder
        }
    }

    /// Фото авто: по правилу отображения (01→02→03→04) из настроек консоли. После посещения всегда 01; если в папке нет 03/04 — показываются имеющиеся с соблюдением порядка.
    @ViewBuilder
    private func carPhotoView(user: User) -> some View {
        let carId = viewModel.displayedCarId ?? user.selectedCarId
        let urlString: String? = {
            if let carId = carId, let car = viewModel.cars.first(where: { $0.id == carId }) {
                return car.urlForDisplayPhoto(preferredBaseName: user.displayPhotoName)
            }
            return viewModel.displayedCarImageURL ?? user.avatarURL
        }()
        if let urlString = urlString, !urlString.isEmpty, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                case .failure:
                    defaultCarImage
                default:
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            defaultCarImage
        }
    }

    /// Изображение авто по умолчанию (файл 01 в Assets) — по ширине поля
    private var defaultCarImage: some View {
        Image("01")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
    }

    /// Плейсхолдер без текста и символов — только нейтральный фон (когда авто не выбран)
    private var emptyPhotoPlaceholder: some View {
        Color(.tertiarySystemFill)
    }
    
    
    // Лаконичные кнопки в едином стиле (текстовые, неброские)
    private var actionsSection: some View {
        VStack(spacing: 0) {
            if viewModel.isEditing {
                Button { viewModel.cancelEditing() } label: {
                    Text("Отменить изменения")
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            
            Button {
                performLogout()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.subheadline)
                    Text("Вернуться к сканированию QR")
                        .font(.subheadline)
                }
                .foregroundStyle(Color(.secondaryLabel))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            
            Divider()
                .padding(.vertical, 4)
            
            Button(role: .destructive) {
                showLogoutConfirm = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline)
                    Text("Выйти из аккаунта")
                        .font(.subheadline)
                }
                .foregroundStyle(Color.red.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Car Selection Sheet

/// Экран выбора типа автомобиля (список папок из веб-консоли)
struct CarSelectionSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingCars {
                    ProgressView("Загрузка...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.cars.isEmpty {
                    ContentUnavailableView(
                        "Нет доступных типов",
                        systemImage: "car",
                        description: Text("Типы автомобилей настраиваются в веб-консоли")
                    )
                } else {
                    List {
                        ForEach(viewModel.cars) { car in
                            Button {
                                Task {
                                    if await viewModel.selectCar(car) {
                                        onDismiss()
                                    }
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    carThumbnail(car)
                                    Text(car.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color(.label))
                                    Spacer()
                                    if (viewModel.displayedCarId ?? viewModel.user?.selectedCarId) == car.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Выбор автомобиля")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { onDismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func carThumbnail(_ car: Car) -> some View {
        Group {
            if let urlString = car.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: Color(.tertiarySystemFill)
                    }
                }
            } else {
                Image(systemName: "car.fill")
                    .font(.title2)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Image Picker (Camera)

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        
        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    var action: (() -> Void)?
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))
                    Text(value)
                        .font(.body)
                        .foregroundStyle(Color(.label))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Social Edit Row

struct SocialEditRow: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
        }
        .padding()
    }
}

// MARK: - Social Edit Row с открытием приложения и вставкой из буфера

struct SocialEditRowWithAppLink: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let color: Color
    var appURL: URL?
    var pasteTransform: (() -> String?)?
    var onOpenApp: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
            
            HStack(spacing: 8) {
                if let url = appURL {
                    Button {
                        onOpenApp?()
                        UIApplication.shared.open(url)
                    } label: {
                        Image(systemName: "arrow.up.forward")
                            .font(.subheadline)
                            .foregroundStyle(color)
                    }
                    .buttonStyle(.plain)
                }
                
                Button {
                    let pasted = pasteTransform?() ?? UIPasteboard.general.string
                    if let s = pasted, !s.isEmpty {
                        text = s
                    }
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

enum PendingMessenger {
    case telegram, vk
}

/// Извлечь юзернейм Telegram из буфера (t.me/xxx, @xxx → xxx)
func cleanTelegramFromClipboard() -> String? {
    guard let raw = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
          !raw.isEmpty else { return nil }
    if raw.hasPrefix("https://t.me/") {
        return String(raw.dropFirst("https://t.me/".count))
    }
    if raw.hasPrefix("t.me/") {
        return String(raw.dropFirst("t.me/".count))
    }
    if raw.hasPrefix("@") {
        return String(raw.dropFirst())
    }
    return raw
}

/// Извлечь юзернейм VK из буфера (vk.com/xxx → xxx)
func cleanVKFromClipboard() -> String? {
    guard let raw = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
          !raw.isEmpty else { return nil }
    if raw.hasPrefix("https://vk.com/") {
        return String(raw.dropFirst("https://vk.com/".count))
    }
    if raw.hasPrefix("vk.com/") {
        return String(raw.dropFirst("vk.com/".count))
    }
    return raw
}

#Preview {
    ProfileView()
        .environmentObject(ProfileViewModel())
        .environmentObject(AppRouter())
}
