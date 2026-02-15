//
//  LoyaltySystemView.swift
//  ServiceBooking
//
//  Экран "Система лояльности": баллы и уровень (Клиент / Постоянный клиент / Прайд)
//

import SwiftUI

/// Пороги баллов для перехода на следующий уровень (условные)
private let pointsThresholdRegular = 200
private let pointsThresholdPride = 500

struct LoyaltySystemView: View {
    @Environment(\.dismiss) private var dismiss
    var user: User?

    private var currentPoints: Int { user?.loyaltyPoints ?? 0 }
    private var clientTier: ClientTier { user?.clientTier ?? .client }
    private var nextRewardPoints: Int {
        switch clientTier {
        case .client: return pointsThresholdRegular
        case .regular: return pointsThresholdPride
        case .pride: return currentPoints + 100
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Карточка с баллами
                    pointsCard
                    
                    // Прогресс до следующей награды
                    progressSection
                    
                    // Преимущества
                    benefitsSection
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Система лояльности")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
    
    private var pointsCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ваши баллы")
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                    Text("\(currentPoints)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                    Text(clientTier.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(.secondaryLabel))
                }
                Spacer()
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor.opacity(0.2))
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var progressSection: some View {
        let toNext = max(0, nextRewardPoints - currentPoints)
        let progressValue: CGFloat = clientTier == .pride ? 1.0 : (nextRewardPoints > 0 ? CGFloat(currentPoints) / CGFloat(nextRewardPoints) : 0)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(clientTier == .pride ? "Максимальный уровень" : "До следующего уровня")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if clientTier != .pride {
                    Text("\(toNext) баллов")
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * min(1, progressValue), height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Преимущества")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                benefitRow(
                    icon: "gift.fill",
                    title: "Бонусы за запись",
                    description: "Получайте баллы за каждую запись",
                    color: .purple
                )
                
                benefitRow(
                    icon: "percent",
                    title: "Скидки",
                    description: "Обменивайте баллы на скидки",
                    color: .orange
                )
                
                benefitRow(
                    icon: "star.fill",
                    title: "Эксклюзивные предложения",
                    description: "Специальные акции для постоянных клиентов",
                    color: .yellow
                )
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func benefitRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.label))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
            }
            
            Spacer()
        }
    }
    
}

#Preview {
    LoyaltySystemView(user: .preview)
}
