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

    var body: some View {
        NavigationStack {
            HomeView(cards: store.cards)
                .overlay {
                    if store.cards.isEmpty && !store.isLoading {
                        ContentUnavailableView("No cards yet",
                            systemImage: "rectangle.stack",
                            description: Text("Tap + to join your first shop."))
                    }
                }
                .navigationTitle("Tapstack")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Sign out") {
                            Task { try? await supabase.auth.signOut() }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showingJoin = true } label: { Image(systemName: "plus") }
                    }
                }
                .task { await store.load() }
                .refreshable { await store.load() }
                .sheet(isPresented: $showingJoin) {
                    JoinShopView(store: store)
                }
        }
    }
}

#Preview {
    ContentView()
}
