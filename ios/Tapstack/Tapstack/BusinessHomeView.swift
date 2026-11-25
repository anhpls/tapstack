//
//  BusinessHomeView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI
import Supabase

struct ShopRole: Decodable, Identifiable, Hashable {
    let shop_id: UUID
    let role: String
    let shops: ShopName
    var id: UUID { shop_id }

    struct ShopName: Decodable, Hashable {
        let name: String
    }
}

struct StampParams: Encodable {
    let p_member_number: String
    let p_count: Int
}

struct AdjustParams: Encodable {
    let p_member_number: String
    let p_change: Int
}

struct BusinessHomeView: View {
    let shop: ShopRole
    let onExit: () -> Void

    @State private var memberNumber = ""
    @State private var card: LoyaltyCard?
    @State private var message: String?
    @State private var isWorking = false
    @State private var count = 1
    @State private var adjustment = 0
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Look up a customer").font(.headline).foregroundStyle(Theme.navy)

                HStack {
                    TextField("TS-1000001", text: $memberNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding()
                        .background(.white, in: RoundedRectangle(cornerRadius: 14))
                    Button("Find") {
                        message = nil
                        Task { await lookUp() }
                    }
                    .disabled(memberNumber.isEmpty || isWorking)
                }

                if let card {
                    CardView(card: card)
                    Stepper("Drinks bought: \(count)", value: $count, in: 1...5)
                        .padding()
                        .background(.white, in: RoundedRectangle(cornerRadius: 14))
                    
                    Button {
                        Task { await giveStamp() }
                    } label: {
                        Label("Give \(count) stamp\(count == 1 ? "" : "s")", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.navy, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                    if card.stamps >= card.stampsNeeded {
                        Button {
                            Task {
                                await callCardFunction("redeem_reward") {
                                    "Reward redeemed! \($0) stamp\($0 == 1 ? "" : "s") carried over."
                                }
                            }
                        } label: {
                            Label("Redeem: \(card.reward)", systemImage: "gift.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }
                        .disabled(isWorking)
                    }

                    if shop.role != "staff" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fix a mistake").font(.subheadline.weight(.semibold))
                            Stepper("Change: \(adjustment > 0 ? "+" : "")\(adjustment)",
                                    value: $adjustment, in: -5...5)
                            Button("Apply correction") {
                                Task { await adjustStamps() }
                            }
                            .disabled(adjustment == 0 || isWorking)
                        }
                        .padding()
                        .background(.white, in: RoundedRectangle(cornerRadius: 14))
                    }
                }

                
                if let message {
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle(shop.shops.name)
            .toolbar {
                Button("Customer mode") { onExit() }
            }
        }
    }

    private func lookUp() async {
        isWorking = true
        defer { isWorking = false }
        do {
            let rows: [MembershipRow] = try await supabase
                .from("memberships")
                .select("id, member_number, shops(id, name, category, color_hex, stamp_programs(stamps_needed, reward)), balance")
                .eq("member_number", value: memberNumber.uppercased())
                .eq("shop_id", value: shop.shop_id.uuidString)
                .execute()
                .value
            card = rows.first?.toCard()
            if card == nil {
                message = "No \(shop.shops.name) card with that number."
            }
        } catch {
            message = error.localizedDescription
        }
    }

    private func giveStamp() async {
        guard let current = card else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let total: Int = try await supabase
                .rpc("give_stamps", params: StampParams(p_member_number: current.memberNumber, p_count: count))
                .execute()
                .value
            UINotificationFeedbackGenerator().notificationOccurred(.success)   // buzz
            await lookUp()
            message = "Stamp added: \(total)/\(current.stampsNeeded)"
        } catch let error as PostgrestError {
            message = error.message          // shows the rule that blocked it
        } catch {
            message = error.localizedDescription
        }
    }
    
    // calls a database function that takes a member number and returns the new balance
    private func callCardFunction(_ name: String, successMessage: @escaping (Int) -> String) async {
        guard let current = card else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let newBalance: Int = try await supabase
                .rpc(name, params: ["p_member_number": current.memberNumber])
                .execute()
                .value
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            await lookUp()
            message = successMessage(newBalance)
        } catch let error as PostgrestError {
            message = error.message
        } catch {
            message = error.localizedDescription
        }
    }
    
    private func adjustStamps() async {
        guard let current = card else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let newBalance: Int = try await supabase
                .rpc("adjust_stamps", params: AdjustParams(p_member_number: current.memberNumber,
                                                           p_change: adjustment))
                .execute()
                .value
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            await lookUp()
            message = "Corrected by \(adjustment > 0 ? "+" : "")\(adjustment). Balance: \(newBalance)."
            adjustment = 0
        } catch let error as PostgrestError {
            message = error.message
        } catch {
            message = error.localizedDescription
        }
    }
}
