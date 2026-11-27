//
//  CardDetailView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

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
    let kind: String       // "visit", "reward" or "adjustment"
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
    @Environment(CardStore.self) private var store
    @State private var previousBrightness: CGFloat = 0.5
    @State private var fadeTask: Task<Void, Never>?
    @State private var history: [HistoryRow] = []
    @State private var showingRedeem = false
    @State private var showingEdit = false
    @State private var confirmRemove = false
    @State private var isRefreshing = false
    @State private var showingVerify = false
    
    var body: some View {
        let card = store.cards.first { $0.id == self.card.id } ?? self.card
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { dismiss() }
                    
                    Button {
                        Task { await refresh() }
                    } label: {
                        Group {
                            if isRefreshing {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .frame(width: 32, height: 32)
                        .background(.white, in: Circle())
                        .foregroundStyle(Theme.navy)
                    }
                    .disabled(isRefreshing)
                }
                .frame(height: 32)
                
                CardView(card: card)
                    .onTapGesture { dismiss() }          // tap the card to close
                
                if card.isVerified {
                    // TAPSTACK CARD: barcode, reward, history
                    
                    VStack(spacing: 8) {
                        BarcodeView(value: card.memberNumber)
                        Text(card.memberNumber)
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    if card.stamps >= card.stampsNeeded {
                        Button {
                            showingRedeem = true
                        } label: {
                            Label("Use reward: \(card.reward)", systemImage: "gift.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }
                    }
                    
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
                } else {
                    // PERSONAL CARD: pending stamps + edit
                    DetailSection(title: "Pending stamps") {
                        PlaceholderRow(icon: "hourglass",
                                       title: "\(card.stamps) of \(card.stampsNeeded) stamps (pending)",
                                       detail: "Show your paper card at \(card.shopName) to confirm them.")
                    }
                    
                    Button {
                        showingVerify = true
                    } label: {
                        Label("Verify at the shop", systemImage: "checkmark.seal")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.navy, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(.white)
                    }

                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit card", systemImage: "pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(Theme.navy)
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
                
                if card.isVerified {
                    Button("Remove from my stack", role: .destructive) { confirmRemove = true }
                        .font(.footnote)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.cream)
        .onAppear {
            // only brighten for cards with a barcode to scan
            guard card.isVerified, let screen = currentScreen else { return }
            previousBrightness = screen.brightness
            fadeTask = Task { await fadeBrightness(to: 1.0, startFast: true) }
        }
        .onDisappear {
            guard card.isVerified else { return }
            fadeTask?.cancel()                               // stop the fade-in if it's still going
            let target = previousBrightness
            Task { await fadeBrightness(to: target) }       // fade back down
        }
        .task { await loadHistory() }
        .fullScreenCover(isPresented: $showingRedeem) {
            RedeemView(card: card)
        }
        .sheet(isPresented: $showingEdit) {
            EditPersonalCardView(card: card) { dismiss() }
        }
        .sheet(isPresented: $showingVerify) {
            VerifyTransferView(card: card) { dismiss() }
        }
        .confirmationDialog("Remove \(card.shopName)?", isPresented: $confirmRemove,
                            titleVisibility: .visible) {
            Button("Remove card", role: .destructive) {
                Task {
                    await store.hide(card)
                    dismiss()
                }
            }
        } message: {
            Text("Your stamps are saved. Join \(card.shopName) again anytime to bring the card back.")
        }
    }
    
    private var currentScreen: UIScreen? {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen
    }
    
    private func loadHistory() async {
        guard card.isVerified else { return }            // personal cards have no history
        history = (try? await supabase
            .rpc("card_history", params: ["p_membership_id": card.id.uuidString])
            .execute()
            .value) ?? []
    }

    private func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await store.load()          // fresh stamps and balances
        await loadHistory()         // fresh history
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    // smoothly moves brightness to a new level instead of jumping
    private func fadeBrightness(to target: CGFloat, duration: Double = 0.25, startFast: Bool = false) async {
        guard let screen = currentScreen else { return }
        let start = screen.brightness
        let steps = 15
        
        for i in 1...steps {
            if Task.isCancelled { return }
            let t = Double(i) / Double(steps)
            let eased = startFast
            ? 1 - pow(1 - t, 3)              // ease out: jumps quickly, then settles
            : t * t * (3 - 2 * t)            // ease in and out: gentle both ends
            screen.brightness = start + (target - start) * eased
            try? await Task.sleep(for: .seconds(duration / Double(steps)))
        }
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
        .environment(CardStore())
}
