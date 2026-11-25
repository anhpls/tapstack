//
//  CardStackView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI

struct CardStackView: View {
    let cards: [LoyaltyCard]
    @State private var selected: LoyaltyCard?

    var body: some View {
        ScrollView {
            VStack(spacing: -110) {          // negative spacing = cards overlap
                ForEach(cards) { card in
                    CardView(card: card)
                        .onTapGesture { selected = card }
                }
            }
            .padding()
        }
        .background(Theme.cream)
        .sheet(item: $selected) { card in
            CardDetailView(card: card)
        }
    }
}

#Preview {
    CardStackView(cards: LoyaltyCard.samples)
}

import Foundation
