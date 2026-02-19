//
//  NewsView.swift
//  ServiceBooking
//

import SwiftUI

struct NewsView: View {
    @StateObject private var viewModel = NewsViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Загрузка новостей…")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage, viewModel.items.isEmpty {
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
                } else if viewModel.items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "newspaper")
                            .font(.system(size: 44))
                            .foregroundStyle(Color(.tertiaryLabel))
                        Text("Новостей пока нет")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.items) { item in
                            Button {
                                Task { await viewModel.markAsRead(item: item) }
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text(item.title)
                                            .font(.headline)
                                            .foregroundStyle(Color(.label))
                                        if !item.read {
                                            Circle()
                                                .fill(Color.accentColor)
                                                .frame(width: 6, height: 6)
                                        }
                                        Spacer()
                                    }
                                    Text(item.body)
                                        .font(.subheadline)
                                        .foregroundStyle(Color(.secondaryLabel))
                                        .lineLimit(4)
                                    Text(item.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(Color(.tertiaryLabel))
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Новости")
            .refreshable { await viewModel.load(silentRefresh: true) }
            .task { await viewModel.load() }
        }
    }
}

#Preview {
    NewsView()
}

