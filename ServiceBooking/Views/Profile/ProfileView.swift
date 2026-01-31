//
//  ProfileView.swift
//  ServiceBooking
//
//  Профиль в стиле карточки
//  Возможность загрузки фото
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @EnvironmentObject var appRouter: AppRouter
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImageData: Data?
    @State private var showImageSourceAlert = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
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
            .onChange(of: selectedPhoto) { _, newItem in
                showImagePicker = false
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        profileImageData = data
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    profileImageData = image.jpegData(compressionQuality: 0.8)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                NavigationStack {
                    VStack(spacing: 24) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Выбрать из галереи", systemImage: "photo.on.rectangle.angled")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                    .padding(24)
                    .navigationTitle("Фото профиля")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Отмена") {
                                showImagePicker = false
                            }
                        }
                    }
                }
            }
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
        ScrollView {
            VStack(spacing: 24) {
                // Главная карточка профиля
                profileCard(user: user)
                
                // Контактная информация
                if viewModel.isEditing {
                    editSection
                } else {
                    contactSection(user: user)
                }
                
                actionsSection
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.loadProfile() }
    }
    
    private func profileCard(user: User) -> some View {
        VStack(spacing: 0) {
            // Верх: Имя и статус
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.isEditing {
                    TextField("Имя", text: $viewModel.editFirstName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(.label))
                    TextField("Фамилия", text: $viewModel.editLastName)
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                } else {
                    Text(user.fullName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(.label))
                    
                    HStack(spacing: 6) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.caption)
                        Text("Клиент")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Фото пропорционально ширине окна (4:3)
            ZStack {
                profilePhotoView(user: user)
                    .aspectRatio(4/3, contentMode: .fill)
                
                // Оверлей для загрузки (без фото)
                if profileImageData == nil && user.avatarURL == nil {
                    Button {
                        #if targetEnvironment(simulator)
                        showImagePicker = true
                        #else
                        showImageSourceAlert = true
                        #endif
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                            Text("Добавить фото")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                } else {
                    // Кнопка смены фото
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Menu {
                                #if !targetEnvironment(simulator)
                                Button {
                                    showCamera = true
                                } label: {
                                    Label("Камера", systemImage: "camera")
                                }
                                #endif
                                Button {
                                    showImagePicker = true
                                } label: {
                                    Label("Выбрать из галереи", systemImage: "photo.on.rectangle")
                                }
                                Button(role: .destructive) {
                                    profileImageData = nil
                                    selectedPhoto = nil
                                } label: {
                                    Label("Удалить фото", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "camera.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 4)
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .aspectRatio(4/3, contentMode: .fit)
            .clipped()
            
            // Низ: Контакт и кнопка (без круглого превью)
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.phone)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(.label))
                    Text("Клиент сервиса")
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))
                }
                Spacer()
                
                // Кнопка действия
                Button {
                    viewModel.openSocialLink(.phone)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.body)
                            .fontWeight(.semibold)
                        Text("Позвонить")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.label))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .alert("Фото профиля", isPresented: $showImageSourceAlert) {
            #if !targetEnvironment(simulator)
            Button("Камера") { showCamera = true }
            #endif
            Button("Галерея") { showImagePicker = true }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Выберите источник фото")
        }
    }
    
    @ViewBuilder
    private func profilePhotoView(user: User) -> some View {
        if let data = profileImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if let avatarURL = user.avatarURL, let url = URL(string: avatarURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    initialsPlaceholder(user: user)
                default:
                    ProgressView()
                }
            }
        } else {
            initialsPlaceholder(user: user)
        }
    }
    
    private func initialsPlaceholder(user: User) -> some View {
        ZStack {
            Color(.tertiarySystemFill)
            Text(user.initials)
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(Color(.tertiaryLabel))
        }
    }
    
    // MARK: - Contact Section
    
    private func contactSection(user: User) -> some View {
        VStack(spacing: 0) {
            ContactRow(icon: "phone.fill", title: "Телефон", value: user.phone, iconColor: .green) {
                viewModel.openSocialLink(.phone)
            }
            if let email = user.email, !email.isEmpty {
                Divider().padding(.leading, 52)
                ContactRow(icon: "envelope.fill", title: "Email", value: email, iconColor: .blue) {
                    viewModel.openSocialLink(.email)
                }
            }
            if user.socialLinks?.hasAnyLink == true {
                Divider().padding(.leading, 52)
                socialContactRows(user: user)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func socialContactRows(user: User) -> some View {
        Group {
            if let t = user.socialLinks?.telegram, !t.isEmpty {
                ContactRow(icon: "paperplane.fill", title: "Telegram", value: t, iconColor: .blue) {
                    viewModel.openSocialLink(.telegram)
                }
                Divider().padding(.leading, 52)
            }
            if let w = user.socialLinks?.whatsapp, !w.isEmpty {
                ContactRow(icon: "message.fill", title: "WhatsApp", value: w, iconColor: .green) {
                    viewModel.openSocialLink(.whatsapp)
                }
                Divider().padding(.leading, 52)
            }
            if let i = user.socialLinks?.instagram, !i.isEmpty {
                ContactRow(icon: "camera.fill", title: "Instagram", value: "@\(i)", iconColor: .purple) {
                    viewModel.openSocialLink(.instagram)
                }
                Divider().padding(.leading, 52)
            }
            if let v = user.socialLinks?.vk, !v.isEmpty {
                ContactRow(icon: "person.2.fill", title: "ВКонтакте", value: v, iconColor: .blue) {
                    viewModel.openSocialLink(.vk)
                }
            }
        }
    }
    
    private var editSection: some View {
        VStack(spacing: 12) {
            Group {
                HStack {
                    Text("Email")
                    Spacer()
                    TextField("Email", text: $viewModel.editEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .multilineTextAlignment(.trailing)
                }
                Divider()
                SocialEditRow(icon: "paperplane.fill", placeholder: "Telegram", text: $viewModel.editTelegram, color: .blue)
                Divider()
                SocialEditRow(icon: "message.fill", placeholder: "WhatsApp", text: $viewModel.editWhatsApp, color: .green)
                Divider()
                SocialEditRow(icon: "camera.fill", placeholder: "Instagram", text: $viewModel.editInstagram, color: .purple)
                Divider()
                SocialEditRow(icon: "person.2.fill", placeholder: "VK", text: $viewModel.editVK, color: .blue)
            }
            .padding(.vertical, 4)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if viewModel.isEditing {
                Button { viewModel.cancelEditing() } label: {
                    Text("Отменить изменения")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
            }
            
            Button {
                appRouter.returnToQRScan()
            } label: {
                Label("Вернуться к сканированию QR", systemImage: "qrcode.viewfinder")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            
            Button(role: .destructive) { } label: {
                Text("Выйти из аккаунта")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
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

#Preview {
    ProfileView()
        .environmentObject(ProfileViewModel())
        .environmentObject(AppRouter())
}
