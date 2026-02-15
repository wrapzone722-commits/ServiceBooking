//
//  PrivacyPolicyView.swift
//  ServiceBooking
//
//  Политика конфиденциальности (краткая, без технических деталей).
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    sectionTitle("1. Общие положения")
                    bodyText("Использование приложения означает согласие с настоящей Политикой. Оператор персональных данных — организация, сервис которой вы подключаете по QR-коду.")
                    
                    sectionTitle("2. Какие данные обрабатываются")
                    bodyText("Обрабатываются данные, которые вы указываете в профиле (имя, фамилия, электронная почта, телефон, контакты в мессенджерах Telegram и VK / Макс, фото), а также данные о ваших записях на услуги. Приложение не собирает данные без вашего действия. Камера используется только для сканирования QR-кода по вашему запросу.")
                    
                    sectionTitle("3. Цели и права")
                    bodyText("Данные используются для доступа к сервису, создания записей, связи с вами (подтверждения, напоминания) и соблюдения законодательства. Вы имеете право запросить информацию об обработке, уточнение или удаление данных, отозвать согласие. Для реализации прав обратитесь в организацию (контакты — на месте оказания услуг или на её ресурсе).")
                    
                    sectionTitle("4. Третьи лица и изменения")
                    bodyText("Данные не передаются третьим лицам в маркетинговых целях. Передача возможна подрядчикам организации или по требованию закона. Оператор вправе обновлять Политику; актуальная версия — в разделе «Политика конфиденциальности» в приложении.")
                    
                    sectionTitle("5. Контакты")
                    bodyText("По вопросам персональных данных обращайтесь в организацию, предоставляющую сервис.")
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Политика конфиденциальности")
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
    PrivacyPolicyView()
}
