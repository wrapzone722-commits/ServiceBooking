//
//  LoyaltyReward.swift
//  ServiceBooking
//
//  Товар или услуга, которые клиент может получить за баллы лояльности.
//

import Foundation

/// Награда за баллы (товар/услуга из списка в веб-консоли)
struct LoyaltyReward: Identifiable, Codable {
    var id: String
    var name: String
    var description: String
    var pointsCost: Int
    var imageURL: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case description
        case pointsCost = "points_cost"
        case imageURL = "image_url"
    }
}

/// Ответ API при обмене баллов на награду
struct RedeemRewardResponse: Decodable {
    let redemptionId: String
    let rewardId: String
    let rewardName: String
    let pointsSpent: Int
    let newBalance: Int

    enum CodingKeys: String, CodingKey {
        case redemptionId = "redemption_id"
        case rewardId = "reward_id"
        case rewardName = "reward_name"
        case pointsSpent = "points_spent"
        case newBalance = "new_balance"
    }
}
