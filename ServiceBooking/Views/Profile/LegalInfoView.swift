//
//  LegalInfoView.swift
//  ServiceBooking
//

import SwiftUI

struct LegalInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Политика конфиденциальности") {
                    PrivacyPolicyView()
                }
                NavigationLink("Условия использования") {
                    TermsOfUseView()
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Юридическая информация")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    LegalInfoView()
}

