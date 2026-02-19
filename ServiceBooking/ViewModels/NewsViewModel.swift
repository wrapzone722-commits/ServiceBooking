//
//  NewsViewModel.swift
//  ServiceBooking
//

import Foundation

@MainActor
final class NewsViewModel: ObservableObject {
    @Published private(set) var items: [ClientNewsItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let api = APIService.shared
    
    func load(silentRefresh: Bool = false) async {
        if !silentRefresh { isLoading = true }
        errorMessage = nil
        do {
            let list = try await api.fetchNews()
            items = list.sorted { $0.createdAt > $1.createdAt }
        } catch {
            if !silentRefresh {
                errorMessage = error.localizedDescription
            }
            items = []
        }
        isLoading = false
    }
    
    func markAsRead(item: ClientNewsItem) async {
        guard !item.read, let id = item.notificationId, !id.isEmpty else { return }
        do {
            try await api.markNotificationRead(id: id)
            if let i = items.firstIndex(where: { $0.id == item.id }) {
                var updated = items[i]
                updated.read = true
                items[i] = updated
            }
        } catch {
            // ignore
        }
    }
}

