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
        if !card.isVerified, let url = card.imageURL {
            // personal card: the real scanned artwork, presented like a premium card
            RealCardView(imageURL: url,
                         aspectRatio: card.imageAspect ?? 1.75,
                         badge: "Not verified · \(card.stamps) pending", title: card.shopName)
        } else {
            standardCard
        }
    }
    
    // Tapstack shop card
    private var standardCard: some View {
        let ready = card.stamps >= card.stampsNeeded
        let ink: Color = card.color.isDark ? .white : Theme.navy   // readable on any shop color
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(card.shopName).font(.title3.bold())
                Spacer()
                Text("\(min(card.stamps, card.stampsNeeded))/\(card.stampsNeeded)")
                    .font(.subheadline.monospacedDigit())
            }
            
            Spacer(minLength: 0)
            
            // stamp slots
            HStack(spacing: 6) {
                ForEach(0..<card.stampsNeeded, id: \.self) { i in
                    Circle()
                        .fill(i < card.stamps ? ink : ink.opacity(0.2))
                        .frame(width: 18, height: 18)
                }
            }
            
            Text(ready
                 ? "🎉 Reward ready: \(card.reward)"
                 : card.stampsNeeded - card.stamps == 1
                 ? "1 visit from: \(card.reward)"
                 : "\(card.stampsNeeded - card.stamps) visits to: \(card.reward)")
            .font(.footnote.weight(ready ? .semibold : .regular))
            .opacity(0.85)
        }
        .foregroundStyle(ink)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .aspectRatio(1.75, contentMode: .fit)            // same shape as a real card
        .background {
            ZStack {
                card.color
                //                ChevronPattern()
                CardSheen()
            }
        }
        .premiumCard()
    }
}

    #Preview {
        CardView(card: LoyaltyCard.samples[1]).padding()
    }
