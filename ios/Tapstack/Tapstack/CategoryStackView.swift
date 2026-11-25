//
//  CategoryStackView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI

struct CategoryStackView: View {
    let category: ShopCategory
    let cards: [LoyaltyCard]
    @Binding var isExpanded: Bool
    let onSelect: (LoyaltyCard) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // header: name, count, arrow
            Button {
                withAnimation(.spring(duration: 0.35)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(category.rawValue).font(.headline)
                    Text("\(cards.count)").font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .foregroundStyle(Theme.navy)
            }

            // collapsed = tightly stacked, expanded = fanned out
            VStack(spacing: isExpanded ? -110 : -165) {
                ForEach(cards) { card in
                    CardView(card: card)
                        .onTapGesture {
                            if isExpanded {
                                onSelect(card)
                            } else {
                                withAnimation(.spring(duration: 0.35)) { isExpanded = true }
                            }
                        }
                }
            }
        }
    }
}
