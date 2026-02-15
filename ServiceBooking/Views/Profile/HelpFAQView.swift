//
//  HelpFAQView.swift
//  ServiceBooking
//
//  Помощь и FAQ (кратко, без технических деталей).
//

import SwiftUI

struct HelpFAQView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    sectionTitle("О приложении")
                    bodyText("Приложение позволяет подключаться к сервису организации по QR-коду, просматривать услуги, записываться на приём и управлять записями.")
                    
                    sectionTitle("Подключение")
                    bodyText("Отсканируйте QR-код, предоставленный организацией (в зале ожидания или на стойке). Подключение выполняется один раз. Если камера недоступна, можно ввести адрес вручную в соответствующем экране.")
                    
                    sectionTitle("Профиль")
                    bodyText("В профиле укажите имя, фамилию, электронную почту и контакты в мессенджерах (Telegram, VK / Макс). Эти данные нужны для связи и уведомлений о записях. Рекомендуем заполнить профиль после первого подключения.")
                    
                    sectionTitle("Записи")
                    bodyText("В разделе «Услуги» выберите услугу, укажите дату и время, при необходимости — комментарий. Записи отображаются в разделе «Записи»; там можно посмотреть статус и отменить запись.")
                    
                    sectionTitle("Уведомления")
                    bodyText("В настройках профиля можно включить push-уведомления и выбрать, за сколько до записи напоминать. Контакты в профиле (email, Telegram, VK / Макс) позволяют организации связываться с вами.")
                    
                    sectionTitle("Поддержка")
                    bodyText("По вопросам работы приложения и записи на услуги обращайтесь в организацию (контакты — на месте оказания услуг или на её сайте).")
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Помощь / FAQ")
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
    HelpFAQView()
}
