//
//  CompanyView.swift
//  ServiceBooking
//

import SwiftUI

struct CompanyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var company: CompanyInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let api = APIService.shared
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading && company == nil {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Загрузка…")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage, company == nil {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 44))
                            .foregroundStyle(Color(.systemOrange))
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Повторить") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if let c = company {
                            Section {
                                Text(c.name)
                                    .font(.headline)
                            }
                            Section("Контакты") {
                                row("Телефон", c.phone)
                                row("Доп. телефон", c.phoneExtra)
                                row("Email", c.email)
                                row("Сайт", c.website)
                            }
                            Section("Реквизиты") {
                                row("Адрес", c.address)
                                row("Юр. адрес", c.legalAddress)
                                row("ИНН", c.inn)
                                row("ОГРН/ОГРНИП", c.ogrn)
                                row("КПП", c.kpp)
                                row("Руководитель", c.directorName)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("О компании")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .task { await load() }
            .refreshable { await load(silentRefresh: true) }
        }
    }
    
    @ViewBuilder
    private func row(_ label: String, _ value: String?) -> some View {
        if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            HStack {
                Text(label)
                Spacer()
                Text(value)
                    .foregroundStyle(Color(.secondaryLabel))
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    @MainActor
    private func load(silentRefresh: Bool = false) async {
        if !silentRefresh { isLoading = true }
        errorMessage = nil
        do {
            company = try await api.fetchCompany()
        } catch {
            if !silentRefresh {
                errorMessage = error.localizedDescription
            }
            company = nil
        }
        isLoading = false
    }
}

#Preview {
    CompanyView()
}

