//
//  LoyaltyCard.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI

// 1. NEW: the list of categories (put it above the struct)
enum ShopCategory: String, CaseIterable {
    case cafe = "Cafés"
    case boba = "Boba"
    case restaurant = "Restaurants"
    case bakery = "Bakeries"
}

struct LoyaltyCard: Identifiable {
    let id = UUID()
    let shopName: String
    let category: ShopCategory
    let memberNumber: String
    let color: Color
    let stamps: Int
    let stampsNeeded: Int
    let reward: String
}

extension LoyaltyCard {
    static let samples: [LoyaltyCard] = [
        LoyaltyCard(shopName: "Oii Sushi", category: .restaurant, memberNumber: "TS-204118",
                    color: Theme.navy, stamps: 6, stampsNeeded: 10, reward: "Free hand roll"),
        LoyaltyCard(shopName: "YunTea", category: .boba, memberNumber: "TS-881902",
                    color: Theme.accent, stamps: 9, stampsNeeded: 10, reward: "Free drink"),
        LoyaltyCard(shopName: "85°C Bakery", category: .bakery, memberNumber: "TS-553017",
                    color: .brown, stamps: 3, stampsNeeded: 8, reward: "Free pastry")
    ]
}

import Foundation
