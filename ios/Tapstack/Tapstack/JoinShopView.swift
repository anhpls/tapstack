//
//  JoinShopView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

// temp replacement for nfc tap sticker during testing
import SwiftUI
import Supabase

struct ShopListItem: Decodable, Identifiable {
    let id: UUID
    let name: String
}

struct JoinShopView: View {
    let store: CardStore
    @Environment(\.dismiss) private var dismiss
    @State private var shops: [ShopListItem] = []

    var body: some View {
        NavigationStack {
            List(shops) { shop in
                HStack {
                    Text(shop.name)
                    Spacer()
                    if store.cards.contains(where: { $0.shopID == shop.id }) {
                        Text("Joined").foregroundStyle(.secondary)
                    } else {
                        Button("Join") {
                            Task { await store.join(shopID: shop.id) }
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .navigationTitle("Join a shop")
            .toolbar { Button("Done") { dismiss() } }
            .task {
                shops = (try? await supabase
                    .from("shops")
                    .select("id, name")
                    .order("name")
                    .execute()
                    .value) ?? []
            }
        }
    }
}
