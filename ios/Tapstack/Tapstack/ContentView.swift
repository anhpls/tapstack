//
//  ContentView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI
import Supabase

struct ContentView: View {
    @State private var store = CardStore()
    @State private var showingJoin = false
    @State private var showingAddOwn = false
    @State private var roles: [ShopRole] = []
    @State private var businessShop: ShopRole?

    var body: some View {
        if let shop = businessShop {
            BusinessHomeView(shop: shop) { businessShop = nil }
        } else {
            NavigationStack {
                HomeView(cards: store.cards)
                    .overlay {
                        if store.cards.isEmpty && !store.isLoading {
                            ContentUnavailableView("No cards yet",
                                                   systemImage: "rectangle.stack",
                                                   description: Text("Tap + to add your first card."))
                        }
                    }
                    .navigationTitle("Tapstack")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Menu {
                                ForEach(roles) { role in
                                    Button("Switch to Business: \(role.shops.name)") {
                                        businessShop = role
                                    }
                                }
                                Button("Sign out", role: .destructive) {
                                    Task { try? await supabase.auth.signOut() }
                                }
                            } label: {
                                Image(systemName: "person.crop.circle")
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button("Join a Tapstack shop", systemImage: "storefront") { showingJoin = true }
                                Button("Add your own card", systemImage: "camera.viewfinder") { showingAddOwn = true }
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }   
                    .task {
                        await store.load()
                        roles = (try? await supabase
                            .from("shop_members")
                            .select("shop_id, role, shops(name)")
                            .execute()
                            .value) ?? []
                    }
                    .refreshable { await store.load() }
                    .sheet(isPresented: $showingJoin) {
                        JoinShopView(store: store)
                    }
                    .sheet(isPresented: $showingAddOwn) {
                        AddPersonalCardView(store: store)
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
