//
//  MessagesViewModel.swift
//  ServiceBooking
//
//  Сообщения от веб-консоли: сервисные уведомления и сообщения администратора.
//  Загружаются с API (GET /notifications).
//

import Foundation

@MainActor
final class MessagesViewModel: ObservableObject {
    @Published private(set) var messages: [ServiceChatMessage] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let api = APIService.shared
    
    /// Загрузить уведомления с сервера
    func load(silentRefresh: Bool = false) async {
        if !silentRefresh { isLoading = true }
        errorMessage = nil
        
        do {
            let list = try await api.fetchNotifications()
            messages = list.sorted { $0.date > $1.date }
        } catch {
            if !silentRefresh {
                errorMessage = error.localizedDescription
            }
            messages = []
        }
        
        isLoading = false
    }
    
    /// Отметить как прочитанное (опционально)
    func markAsRead(id: String) async {
        do {
            try await api.markNotificationRead(id: id)
            if let i = messages.firstIndex(where: { $0.id == id }) {
                var msg = messages[i]
                msg.isRead = true
                messages[i] = msg
            }
        } catch {
            // Игнорируем ошибку отметки
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}
