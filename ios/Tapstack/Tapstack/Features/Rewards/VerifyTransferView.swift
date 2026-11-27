//
//  VerifyTransferView.swift
//  Tapstack
//

import SwiftUI
import Supabase

struct TransferRequest: Decodable {
    let id: UUID
    let code: String
}

struct TransferParams: Encodable {
    let p_personal_card_id: String
    let p_shop_id: String
}

// customer side: turn a personal (paper) card into an official Tapstack card
struct VerifyTransferView: View {
    let card: LoyaltyCard
    let onDone: () -> Void
    @Environment(CardStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var shops: [ShopListItem] = []
    @State private var request: TransferRequest?
    @State private var completed = false
    @State private var errorMessage: String?

    // shops whose name matches the card go first
    private var sortedShops: [ShopListItem] {
        shops.sorted { a, _ in a.name.localizedCaseInsensitiveContains(card.shopName) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if completed {
                    VStack(spacing: 16) {
                        Text("🎉").font(.system(size: 64))
                        Text("Verified!").font(.title.bold())
                        Text("Your \(card.shopName) card is now official. New stamps will be added digitally.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("Done") { onDone() }
                            .font(.headline)
                            .padding(.top)
                    }
                    .padding(32)
                } else if let request {
                    VStack(spacing: 20) {
                        Text("Show this and your paper card to staff")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Text(request.code)
                            .font(.system(size: 56, weight: .bold, design: .monospaced))
                            .tracking(8)
                        Text("\(card.stamps) stamps to verify")
                            .foregroundStyle(.secondary)
                        ProgressView("Waiting for staff…")
                            .padding(.top)
                    }
                    .padding(32)
                } else {
                    List {
                        Section {
                            ForEach(sortedShops) { shop in
                                Button(shop.name) {
                                    Task { await start(shop) }
                                }
                            }
                        } header: {
                            Text("Which Tapstack shop is this card from?")
                        } footer: {
                            Text("Don't see it? This shop isn't on Tapstack yet.")
                        }
                        if let errorMessage {
                            Text(errorMessage).foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("Verify card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !completed {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                }
            }
            .task {
                shops = (try? await supabase
                    .from("shops")
                    .select("id, name")
                    .order("name")
                    .execute()
                    .value) ?? []
            }
        }
    }

    private func start(_ shop: ShopListItem) async {
        do {
            let rows: [TransferRequest] = try await supabase
                .rpc("request_transfer", params: TransferParams(p_personal_card_id: card.id.uuidString,
                                                                p_shop_id: shop.id.uuidString))
                .execute()
                .value
            request = rows.first
            await waitForStaff()
        } catch let error as PostgrestError {
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // checks every 3 seconds until staff confirm (up to 10 minutes)
    private func waitForStaff() async {
        guard let id = request?.id else { return }
        let deadline = Date().addingTimeInterval(600)
        while !Task.isCancelled && Date() < deadline {
            try? await Task.sleep(for: .seconds(3))
            let rows: [RequestStatus] = (try? await supabase
                .from("transfer_requests")
                .select("status")
                .eq("id", value: id.uuidString)
                .execute()
                .value) ?? []
            if rows.first?.status == "completed" {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                await store.load()
                withAnimation(.spring) { completed = true }
                return
            }
        }
    }
}
