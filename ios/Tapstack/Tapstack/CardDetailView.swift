//
//  CardDetailView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI

struct CardDetailView: View {
    let card: LoyaltyCard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            CardView(card: card)

            VStack(spacing: 8) {
                BarcodeView(value: card.memberNumber)
                Text(card.memberNumber)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Spacer()

            Button("Done") { dismiss() }
                .font(.headline)
                .foregroundStyle(Theme.navy)
        }
        .padding()
        .background(Theme.cream)
    }
}

#Preview {
    CardDetailView(card: LoyaltyCard.samples[0])
}

import Foundation
