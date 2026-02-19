//
//  NewsItem.swift
//  ServiceBooking
//
//  Новости от веб-консоли (GET /news) для клиента.
//

import Foundation

struct ClientNewsItem: Identifiable, Decodable, Equatable {
    let id: String
    let title: String
    let body: String
    let createdAt: Date
    let published: Bool
    var read: Bool
    let notificationId: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case body
        case createdAt = "created_at"
        case published
        case read
        case notificationId = "notification_id"
    }
}

