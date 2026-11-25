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
                    color: Theme.sky, stamps: 6, stampsNeeded: 10, reward: "Free hand roll"),
        LoyaltyCard(shopName: "YunTea", category: .boba, memberNumber: "TS-881902",
                    color: Theme.peach, stamps: 9, stampsNeeded: 10, reward: "Free drink"),
        LoyaltyCard(shopName: "85°C Bakery", category: .bakery, memberNumber: "TS-553017",
                    color: Theme.butter, stamps: 3, stampsNeeded: 8, reward: "Free pastry"),
        LoyaltyCard(shopName: "Lotus Boba", category: .boba, memberNumber: "TS-310455",
                    color: Theme.mint, stamps: 4, stampsNeeded: 10, reward: "Free drink"),
        LoyaltyCard(shopName: "Morning Pour", category: .cafe, memberNumber: "TS-772031",
                    color: Theme.lavender, stamps: 7, stampsNeeded: 8, reward: "Free latte"),
        LoyaltyCard(shopName: "Bean There", category: .cafe, memberNumber: "TS-118640",
                    color: Theme.sage, stamps: 2, stampsNeeded: 10, reward: "Free coffee"),
        LoyaltyCard(shopName: "Pho Corner", category: .restaurant, memberNumber: "TS-905562",
                    color: Theme.rose, stamps: 5, stampsNeeded: 10, reward: "Free appetizer")
    ]
}
