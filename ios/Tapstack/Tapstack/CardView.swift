//
//  CardView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI

struct CardView: View {
    let card: LoyaltyCard

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(card.shopName).font(.title3.bold())
                Spacer()
                Text("\(card.stamps)/\(card.stampsNeeded)").font(.subheadline.monospacedDigit())
            }

            // stamp slots
            HStack(spacing: 6) {
                ForEach(0..<card.stampsNeeded, id: \.self) { i in
                    Circle()
                        .fill(i < card.stamps ? Theme.navy : Theme.navy.opacity(0.12))
                        .frame(width: 18, height: 18)
                }
            }

            Text(card.stampsNeeded - card.stamps == 1
                 ? "1 visit from: \(card.reward)"
                 : "\(card.stampsNeeded - card.stamps) visits to: \(card.reward)")
                .font(.footnote)
                .opacity(0.85)
        }
        .foregroundStyle(Theme.navy)
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .background(card.color, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

#Preview {
    CardView(card: LoyaltyCard.samples[1]).padding()
}

