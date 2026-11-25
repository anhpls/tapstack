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
    @State private var previousBrightness: CGFloat = 0.5
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CardView(card: card)
                    .onTapGesture { dismiss() }          // tap the card to close
                
                // barcode
                VStack(spacing: 8) {
                    BarcodeView(value: card.memberNumber)
                    Text(card.memberNumber)
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                // deals (placeholder)
                DetailSection(title: "Deals") {
                    PlaceholderRow(icon: "tag", title: "Lorem ipsum dolor", detail: "Sit amet consectetur · Ends Dec 12")
                    PlaceholderRow(icon: "tag", title: "Adipiscing elit sed", detail: "Do eiusmod tempor · Ends Dec 20")
                }
                
                // stamp history (placeholder)
                DetailSection(title: "Stamp history") {
                    PlaceholderRow(icon: "checkmark.seal", title: "Lorem ipsum", detail: "Nov 22 · +1 stamp")
                    PlaceholderRow(icon: "checkmark.seal", title: "Dolor sit amet", detail: "Nov 15 · +1 stamp")
                    PlaceholderRow(icon: "checkmark.seal", title: "Consectetur", detail: "Nov 8 · +1 stamp")
                }
                
                // open in shop app (placeholder, does nothing yet)
                Button {
                    // later: deep link into the shop's own app
                } label: {
                    Label("Open in \(card.shopName) app", systemImage: "arrow.up.right.square")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.navy, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .padding(.top, 8)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.cream)
        .onAppear {
            if let screen = currentScreen {
                previousBrightness = screen.brightness
                screen.brightness = 1.0
            }
        }
        .onDisappear {
            currentScreen?.brightness = previousBrightness
        }
    }
    private var currentScreen: UIScreen? {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen
    }
}

// a titled white box that holds rows
struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundStyle(Theme.navy)
            VStack(spacing: 0) { content }
                .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// one row: icon, title, detail line
struct PlaceholderRow: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.medium))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
    }
}

#Preview {
    CardDetailView(card: LoyaltyCard.samples[0])
}

