//
//  TermsOfUseView.swift
//  ServiceBooking
//
//  Условия использования (краткие, без технических деталей).
//

import SwiftUI

struct TermsOfUseView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    sectionTitle("1. Принятие условий")
                    bodyText("Использование приложения означает согласие с настоящими Условиями. Сервис предоставляет организация, к которой вы подключаетесь по QR-коду.")
                    
                    sectionTitle("2. Сервис")
                    bodyText("Приложение позволяет подключаться к сервису организации, просматривать услуги, создавать и отменять записи, управлять профилем и получать уведомления. Функциональность определяется организацией.")
                    
                    sectionTitle("3. Правила")
                    bodyText("Предоставляйте достоверные данные в профиле. Не используйте приложение для незаконной деятельности и несанкционированного доступа к данным других пользователей. При нарушении доступ может быть ограничен.")
                    
                    sectionTitle("4. Ответственность")
                    bodyText("Сервис предоставляется «как есть». Оператор не несёт ответственности за косвенные убытки, сбои связи и действия третьих лиц в пределах, допускаемых законом.")
                    
                    sectionTitle("5. Изменения и контакты")
                    bodyText("Условия могут изменяться; новая редакция публикуется в приложении. По вопросам обращайтесь в организацию (контакты — на месте оказания услуг или на её ресурсе).")
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Условия использования")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Color(.label))
    }
    
    private func bodyText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Color(.secondaryLabel))
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    TermsOfUseView()
}
