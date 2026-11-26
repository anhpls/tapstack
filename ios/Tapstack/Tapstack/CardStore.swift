//
//  CardStore.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI
import Supabase
import Observation

// shapes of the database response
struct MembershipRow: Decodable {
    let id: UUID
    let member_number: String
    let shops: ShopEmbed
    let balance: Int

    struct ShopEmbed: Decodable {
        let id: UUID
        let name: String
        let category: String
        let color_hex: String
        let stamp_programs: [ProgramEmbed]
    }
    struct ProgramEmbed: Decodable {
        let stamps_needed: Int
        let reward: String
    }
 

    // database row -> the card your views already know how to draw
    func toCard() -> LoyaltyCard? {
        guard let program = shops.stamp_programs.first,
              let category = ShopCategory(rawValue: shops.category) else { return nil }
        return LoyaltyCard(
            id: id,
            shopName: shops.name,
            category: category,
            memberNumber: member_number,
            color: Color(hex: shops.color_hex),
            stamps: balance,
            stampsNeeded: program.stamps_needed,
            reward: program.reward,
            shopID: shops.id
        )
    }
}

struct PersonalCardRow: Decodable {
    let id: UUID
    let shop_name: String
    let category: String
    let stamps_needed: Int
    let pending_stamps: Int
    let image_path: String?
    let image_back_path: String?
    let image_aspect: Double?
}

@Observable @MainActor
final class CardStore {
    var cards: [LoyaltyCard] = []
    var isLoading = false
    var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let rows: [MembershipRow] = try await supabase
                .from("memberships")
                .select("id, member_number, shops(id, name, category, color_hex, stamp_programs(stamps_needed, reward)), balance")
                .order("created_at")
                .execute()
                .value
            var all = rows.compactMap { $0.toCard() }

            let personal: [PersonalCardRow] = try await supabase
                .from("personal_cards")
                .select()
                .order("created_at")
                .execute()
                .value

            for row in personal {
                all.append(LoyaltyCard(
                    id: row.id,
                    shopName: row.shop_name,
                    category: ShopCategory(rawValue: row.category) ?? .cafe,
                    memberNumber: "",
                    color: Theme.navy,
                    stamps: row.pending_stamps,
                    stampsNeeded: row.stamps_needed,
                    reward: "Reward",
                    imageURL: await signedURL(row.image_path),
                    backImageURL: await signedURL(row.image_back_path),
                    isVerified: false,
                    imageAspect: row.image_aspect.map { CGFloat($0) }
                ))
            }
            cards = all
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func join(shopID: UUID) async {
        do {
            let userID = try await supabase.auth.session.user.id
            try await supabase
                .from("memberships")
                .insert(["user_id": userID.uuidString, "shop_id": shopID.uuidString])
                .execute()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // private images need a temporary signed link (valid 1 hour)
    private func signedURL(_ path: String?) async -> URL? {
        guard let path else { return nil }
        return try? await supabase.storage
            .from("card-images")
            .createSignedURL(path: path, expiresIn: 3600)
    }
}
