//
//  ServiceChatView.swift
//  ServiceBooking
//
//  Сообщения от веб-консоли: сервисные уведомления и сообщения администратора.
//  Загружаются с API (GET /notifications).
//

import SwiftUI

struct ServiceChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MessagesViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.messages.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Загрузка сообщений…")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage, viewModel.messages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 44))
                            .foregroundStyle(Color(.systemOrange))
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Повторить") {
                            Task { await viewModel.load() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.messages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(.tertiaryLabel))
                        Text("Нет сообщений")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                        Text("Здесь будут сервисные уведомления и сообщения от администратора веб-консоли.")
                            .font(.caption)
                            .foregroundStyle(Color(.tertiaryLabel))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(viewModel.messages) { msg in
                                    ChatBubbleView(message: msg)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            if let last = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Сообщения")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                await viewModel.load(silentRefresh: true)
            }
            .task {
                await viewModel.load()
            }
        }
    }
}

private struct ChatBubbleView: View {
    let message: ServiceChatMessage
    
    private var timeString: String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: message.date)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: message.source.iconName)
                .font(.caption)
                .foregroundStyle(message.source == .admin ? Color.accentColor : Color(.secondaryLabel))
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(message.source.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(message.source == .admin ? Color.accentColor : Color(.secondaryLabel))
                    if !message.isRead {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                    }
                }
                if let title = message.title, !title.isEmpty {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(.label))
                }
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(Color(.label))
                Text(timeString)
                    .font(.caption2)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(message.source == .admin ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Spacer(minLength: 24)
        }
    }
}

#Preview {
    ServiceChatView()
}
