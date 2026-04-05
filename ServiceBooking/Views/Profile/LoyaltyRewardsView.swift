//
//  LoyaltyRewardsView.swift
//  ServiceBooking
//
//  Список товаров и услуг за баллы: клиент выбирает и обменивает баллы.
//

import SwiftUI

struct LoyaltyRewardsView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    @State private var rewards: [LoyaltyReward] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedReward: LoyaltyReward?
    @State private var showRedeemConfirm = false
    @State private var redeemError: String?
    @State private var redeemSuccess: String?

    private var currentPoints: Int { profileViewModel.user?.loyaltyPoints ?? 0 }

    var body: some View {
        Group {
            if isLoading && rewards.isEmpty {
                ProgressView("Загрузка…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let msg = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(msg)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(rewards) { reward in
                            rewardRow(reward)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Товары и услуги за баллы")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadRewards() }
        .refreshable { await loadRewards() }
        .alert("Обменять баллы?", isPresented: $showRedeemConfirm) {
            Button("Отмена", role: .cancel) {
                selectedReward = nil
                redeemError = nil
            }
            if let r = selectedReward, currentPoints >= r.pointsCost {
                Button("Обменять") {
                    Task { await redeem(r) }
                }
            }
        } message: {
            if let r = selectedReward {
                Text("Списать \(r.pointsCost) баллов и получить: «\(r.name)». У вас: \(currentPoints) баллов.")
            }
        }
        .alert("Ошибка", isPresented: .constant(redeemError != nil)) {
            Button("OK") { redeemError = nil; selectedReward = nil }
        } message: {
            if let e = redeemError { Text(e) }
        }
        .alert("Готово", isPresented: .constant(redeemSuccess != nil)) {
            Button("OK") { redeemSuccess = nil; selectedReward = nil }
        } message: {
            if let s = redeemSuccess { Text(s) }
        }
    }

    private func rewardRow(_ reward: LoyaltyReward) -> some View {
        let canAfford = currentPoints >= reward.pointsCost
        return Button {
            selectedReward = reward
            if !canAfford {
                redeemError = "Недостаточно баллов. Нужно: \(reward.pointsCost), у вас: \(currentPoints)."
                return
            }
            showRedeemConfirm = true
        } label: {
            HStack(spacing: 16) {
                Group {
                    if let u = reward.imageURL, !u.isEmpty {
                        CompressedRemoteImage(urlString: u, maxPixelSide: 180, contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 56, height: 56)
                            Image(systemName: "gift.fill")
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(reward.name)
                        .font(.headline)
                        .foregroundStyle(Color(.label))
                    if !reward.description.isEmpty {
                        Text(reward.description)
                            .font(.caption)
                            .foregroundStyle(Color(.secondaryLabel))
                            .lineLimit(2)
                    }
                    Text("\(reward.pointsCost) баллов")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(canAfford ? Color.accentColor : Color(.secondaryLabel))
                }
                Spacer()
                if canAfford {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private func loadRewards() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            rewards = try await APIService.shared.fetchRewards()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func redeem(_ reward: LoyaltyReward) async {
        showRedeemConfirm = false
        isLoading = true
        redeemError = nil
        redeemSuccess = nil
        defer { isLoading = false }
        do {
            let response = try await APIService.shared.redeemReward(rewardId: reward.id)
            await profileViewModel.loadProfile(silentRefresh: true)
            redeemSuccess = "Вы получили: \(response.rewardName). Новый баланс: \(response.newBalance) баллов."
        } catch let err as APIError {
            switch err {
            case .serverError(400, let msg):
                redeemError = msg ?? "Недостаточно баллов."
            default:
                redeemError = err.localizedDescription
            }
        } catch {
            redeemError = error.localizedDescription
        }
        selectedReward = nil
    }
}

#Preview {
    NavigationStack {
        LoyaltyRewardsView()
            .environmentObject(ProfileViewModel())
    }
}
