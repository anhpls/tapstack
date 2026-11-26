//
//  HomeView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI

struct HomeView: View {
    let cards: [LoyaltyCard]
    @State private var selected: LoyaltyCard?
    @State private var expanded: Set<ShopCategory> = []
    @State private var query = ""
    let onRefresh: () async -> Void
    
    // cards 1 stamp away from a reward
    private var almostThere: [LoyaltyCard] {
        cards.filter { $0.stampsNeeded - $0.stamps <= 1 }
    }
    // cards whose shop name matches the search
    private var results: [LoyaltyCard] {
        cards.filter { $0.shopName.localizedCaseInsensitiveContains(query) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if !query.isEmpty {
                    // SEARCHING: flat list of matches
                    if results.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                            Text("No cards match \"\(query)\"")
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        ForEach(results) { card in
                            CardView(card: card).onTapGesture { selected = card }
                        }
                    }
                } else {
                    // NOT SEARCHING: normal home screen
                    if !almostThere.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Almost there").font(.headline).foregroundStyle(Theme.navy)
                            ForEach(almostThere) { card in
                                CardView(card: card).onTapGesture { selected = card }
                            }
                        }
                    }
                    
                    ForEach(ShopCategory.allCases, id: \.self) { category in
                        let group = cards.filter { $0.category == category }
                        if !group.isEmpty {
                            CategoryStackView(
                                category: category,
                                cards: group,
                                isExpanded: binding(for: category),
                                onSelect: { selected = $0 }
                            )
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .refreshable {
            await onRefresh()
        }
        .background(Theme.cream.ignoresSafeArea())
        .searchable(text: $query, prompt: "Search your cards")
        .sheet(item: $selected) { card in
            CardDetailView(card: card)
        }
    }
    
    // turns "is this category in the set?" into a true/false switch
    private func binding(for category: ShopCategory) -> Binding<Bool> {
        Binding(
            get: { expanded.contains(category) },
            set: { isOn in
                if isOn { expanded.insert(category) } else { expanded.remove(category) }
            }
        )
    }
}

#Preview {
    NavigationStack {
        HomeView(cards: LoyaltyCard.samples, onRefresh: {}).navigationTitle("Tapstack")
    }
}
