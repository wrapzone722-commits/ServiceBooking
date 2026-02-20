//
//  BookingCreationView.swift
//  ServiceBooking
//
//  Экран создания записи
//  Стиль iOS — светлая и тёмная темы
//

import SwiftUI

struct BookingCreationView: View {
    let service: Service
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bookingsViewModel: BookingsViewModel
    
    @State private var notes: String = ""
    @State private var showConfirmation = false
    @State private var showErrorAlert = false
    @State private var reminderTiming: ReminderTiming = .d1
    
    private static let calendar = Calendar.current
    
    /// Диапазон дат: только предстоящие, интервал 2 недели вперёд от сегодня
    private static var dateRange: ClosedRange<Date> {
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 14, to: start) ?? start
        return start...end
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    serviceInfoSection
                    dateSelectionSection
                    postSelectionSection
                    timeSelectionSection
                    reminderSection
                    notesSection
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("Запись на услугу")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { confirmButton }
            .onChange(of: bookingsViewModel.selectedDate) { _, newDate in
                Task {
                    await bookingsViewModel.loadAvailableSlots(serviceId: service.id, date: newDate)
                }
            }
            .onChange(of: bookingsViewModel.selectedPostId) { _, _ in
                Task {
                    await bookingsViewModel.loadAvailableSlots(serviceId: service.id, date: bookingsViewModel.selectedDate)
                }
            }
            .task {
                clampSelectedDateToRange()
                await bookingsViewModel.loadPosts()
                await bookingsViewModel.loadAvailableSlots(serviceId: service.id, date: bookingsViewModel.selectedDate)
            }
            .onAppear {
                clampSelectedDateToRange()
            }
            .alert("Запись создана!", isPresented: $showConfirmation) {
                Button("Отлично") { dismiss() }
            } message: {
                Text("Ваша запись на \(service.name) успешно создана. Ожидайте подтверждения.")
            }
            .alert("Ошибка записи", isPresented: $showErrorAlert) {
                Button("OK") {
                    showErrorAlert = false
                    bookingsViewModel.errorMessage = nil
                }
            } message: {
                Text(bookingsViewModel.errorMessage ?? "Не удалось создать запись.")
            }
        }
    }
    
    private var serviceInfoSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(service.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.label)
                Text(service.category)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryLabel)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(service.formattedPrice)
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(service.formattedDuration)
                        .font(.caption)
                }
                .foregroundStyle(AppTheme.secondaryLabel)
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }
    
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Выберите дату")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.label)
            
            DatePicker("Дата", selection: $bookingsViewModel.selectedDate, in: Self.dateRange, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .environment(\.locale, Locale(identifier: "ru_RU"))
        }
    }
    
    @ViewBuilder
    private var postSelectionSection: some View {
        if !bookingsViewModel.posts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Пост")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.label)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(bookingsViewModel.posts.filter { $0.isEnabled }) { post in
                            PostChipButton(
                                post: post,
                                isSelected: bookingsViewModel.selectedPostId == post.id
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    bookingsViewModel.selectedPostId = post.id
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    /// Ограничить выбранную дату диапазоном «сегодня — +2 недели»
    private func clampSelectedDateToRange() {
        let start = Self.calendar.startOfDay(for: Date())
        guard let end = Self.calendar.date(byAdding: .day, value: 14, to: start) else { return }
        if bookingsViewModel.selectedDate < start {
            bookingsViewModel.selectedDate = start
        } else if bookingsViewModel.selectedDate > end {
            bookingsViewModel.selectedDate = end
        }
    }
    
    private var timeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Выберите время")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.label)
                Spacer()
                if bookingsViewModel.isSlotsLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if bookingsViewModel.availableSlotsForSelection.isEmpty && !bookingsViewModel.isSlotsLoading {
                Text("Нет доступных слотов на выбранную дату")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryLabel)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.tertiaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(bookingsViewModel.availableSlotsForSelection) { slot in
                        TimeSlotButton(
                            slot: slot,
                            isSelected: bookingsViewModel.selectedSlot?.id == slot.id
                        ) { bookingsViewModel.selectSlot(slot) }
                    }
                }
            }
        }
    }
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Напомнить о записи")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.label)
            
            Picker("", selection: $reminderTiming) {
                ForEach(ReminderTiming.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Комментарий")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.label)
            
            TextField("Дополнительные пожелания (необязательно)", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .padding()
                .background(AppTheme.tertiaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .lineLimit(3...6)
        }
    }
    
    private var confirmButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 12) {
                if bookingsViewModel.selectedSlot != nil {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatSelectedDateTime())
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryLabel)
                            Text(service.formattedPrice)
                                .font(.headline)
                                .foregroundStyle(Color.accentColor)
                        }
                        Spacer()
                    }
                }
                
                Button {
                    Task {
                        let success = await bookingsViewModel.createBooking(serviceId: service.id, notes: notes.isEmpty ? nil : notes)
                        if success {
                            showConfirmation = true
                        } else {
                            showErrorAlert = true
                        }
                    }
                } label: {
                    HStack {
                        if bookingsViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Подтвердить запись")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(bookingsViewModel.selectedSlot == nil || bookingsViewModel.isLoading)
            }
            .padding()
            .background(AppTheme.secondaryBackground)
        }
    }

    private func formatSelectedDateTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        let dateString = formatter.string(from: bookingsViewModel.selectedDate)
        let timeString = bookingsViewModel.selectedSlot?.formattedTime ?? ""
        return "\(dateString), \(timeString)"
    }
}

// MARK: - Post (бокс) — интерактивная кнопка-чип

struct PostChipButton: View {
    let post: Post
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.caption)
                Text(post.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentColor : AppTheme.tertiaryBackground)
            .foregroundStyle(isSelected ? .white : AppTheme.label)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Time Slot Button

struct TimeSlotButton: View {
    let slot: TimeSlot
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(slot.formattedTime)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.accentColor : AppTheme.tertiaryBackground)
                .foregroundStyle(isSelected ? .white : AppTheme.label)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BookingCreationView(service: Service(
        id: "preview_service",
        name: "Мойка кузова",
        description: "Бесконтактная мойка с воском",
        price: 800,
        duration: 30,
        category: "Автоуслуги",
        imageURL: nil,
        isActive: true
    ))
        .environmentObject(BookingsViewModel())
}
