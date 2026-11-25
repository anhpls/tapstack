//
//  ContentView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI
import Supabase

struct ShopRow: Decodable {
    let id: UUID
    let name: String
    let category: String
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            HomeView(cards: LoyaltyCard.samples)
                .navigationTitle("Tapstack")
                .task {
                    do {
                        let shops: [ShopRow] = try await supabase
                            .from("shops")
                            .select()
                            .execute()
                            .value
                        print("✅ Connected! Found \(shops.count) shops:", shops.map(\.name))
                    } catch {
                        print("❌ Supabase error:", error)
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
