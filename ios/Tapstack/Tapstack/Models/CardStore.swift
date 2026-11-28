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
    let image_back_aspect: Double?
}

struct PersonalCardUpdate: Encodable {
    let shop_name: String
    let pending_stamps: Int
    let image_path: String?
    let image_back_path: String?
    let image_aspect: Double?
    let image_back_aspect: Double?
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
            // only my own cards: staff can also read their shop's customers' memberships
            // (business mode needs that), so without this filter those would show in my stack
            let userID = try await supabase.auth.session.user.id
            let rows: [MembershipRow] = try await supabase
                .from("memberships")
                .select("id, member_number, shops(id, name, category, color_hex, stamp_programs(stamps_needed, reward)), balance")
                .eq("user_id", value: userID.uuidString)
                .is("hidden_at", value: nil)
                .order("created_at")
                .execute()
                .value
            var all = rows.compactMap { $0.toCard() }

            let personal: [PersonalCardRow] = try await supabase
                .from("personal_cards")
                .select()
                .is("transferred_at", value: nil)      // hide cards already verified
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
                    imageAspect: row.image_aspect.map { CGFloat($0) },
                    backImageAspect: row.image_back_aspect.map { CGFloat($0) },
                    imagePath: row.image_path,
                    backImagePath: row.image_back_path
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
            try await supabase
                .rpc("join_shop", params: ["p_shop_id": shopID.uuidString])
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
    
    // Tapstack card: hide it (shop keeps its records)
    func hide(_ card: LoyaltyCard) async {
        do {
            try await supabase
                .rpc("hide_membership", params: ["p_membership_id": card.id.uuidString])
                .execute()
            await load()
        } catch {
            // DEBUG (remove-card bug): which card and user did the database reject?
            let uid = try? await supabase.auth.session.user.id
            print("DEBUG hide failed | card \(card.id) | shop \(card.shopName) | user \(uid?.uuidString ?? "none") | \(error)")
            errorMessage = error.localizedDescription
        }
    }

    // personal card: delete the row and its photos
    func deletePersonal(_ card: LoyaltyCard) async {
        do {
            let paths = [card.imagePath, card.backImagePath].compactMap { $0 }
            if !paths.isEmpty {
                _ = try? await supabase.storage.from("card-images").remove(paths: paths)
            }
            try await supabase
                .from("personal_cards")
                .delete()
                .eq("id", value: card.id.uuidString)
                .execute()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // personal card: rename, fix stamps, or swap which side is the front
    func updatePersonal(_ card: LoyaltyCard, name: String, pending: Int, swapSides: Bool) async {
        let update = PersonalCardUpdate(
            shop_name: name,
            pending_stamps: pending,
            image_path: swapSides ? card.backImagePath : card.imagePath,
            image_back_path: swapSides ? card.imagePath : card.backImagePath,
            image_aspect: (swapSides ? card.backImageAspect : card.imageAspect).map { Double($0) },
            image_back_aspect: (swapSides ? card.imageAspect : card.backImageAspect).map { Double($0) }
        )
        do {
            try await supabase
                .from("personal_cards")
                .update(update)
                .eq("id", value: card.id.uuidString)
                .execute()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
