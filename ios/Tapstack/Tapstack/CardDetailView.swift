//
//  CardDetailView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI
import Supabase

struct HistoryRow: Decodable, Identifiable {
    let happened_at: Date
    let kind: String       // "visit", "reward" or "correction"
    let change: Int
    let bonus: Int
    let note: String?
    var id: String { "\(kind)-\(happened_at.timeIntervalSince1970)" }
    
    var icon: String {
        switch kind {
        case "reward": "gift.fill"
        case "adjustment": "slider.horizontal.3"
        default: "checkmark.seal"
        }
    }
    
    var title: String {
            switch kind {
            case "reward":
                return "Redeemed: \(note ?? "reward")"
            case "adjustment":
                return "Stamps adjusted by the shop: \(change > 0 ? "+" : "")\(change)"
            default:
                let base = "+\(change) stamp\(change == 1 ? "" : "s")"
                return bonus > 0 ? "\(base) (incl. \(bonus) bonus)" : base
            }
        
    }
}

struct CardDetailView: View {
    let card: LoyaltyCard
    @Environment(\.dismiss) private var dismiss
    @State private var previousBrightness: CGFloat = 0.5
    @State private var history: [HistoryRow] = []
    
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
                
                DetailSection(title: "Stamp history") {
                    if history.isEmpty {
                        PlaceholderRow(icon: "clock", title: "No stamps yet",
                                       detail: "Your visits will show up here.")
                    } else {
                        ForEach(history) { row in
                            PlaceholderRow(icon: row.icon,
                                           title: row.title,
                                           detail: row.happened_at.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
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
        .task {
            history = (try? await supabase
                .rpc("card_history", params: ["p_membership_id": card.id.uuidString])
                .execute()
                .value) ?? []
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

