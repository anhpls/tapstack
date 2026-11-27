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

struct PendingRequest: Decodable {
    let code: String
}

struct AdjustParams: Encodable {
    let p_member_number: String
    let p_change: Int
}

struct PendingTransfer: Decodable {
    let code: String
    let claimed_stamps: Int
}

struct CompleteTransferParams: Encodable {
    let p_code: String
    let p_shop_id: String
    let p_confirmed: Int
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
    @State private var pendingCode: String?
    @State private var transferCode = ""
    @State private var transfer: PendingTransfer?
    @State private var confirmCount = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
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
                    if let pendingCode {
                        Label("Customer is redeeming: \(card.reward) · Code \(pendingCode)",
                              systemImage: "gift.fill")
                            .font(.subheadline.weight(.semibold))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                    }
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

                Divider().padding(.vertical, 8)

                // turn a customer's paper card into real stamps
                Text("Paper card transfer").font(.headline).foregroundStyle(Theme.navy)

                HStack {
                    TextField("4-digit code", text: $transferCode)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(.white, in: RoundedRectangle(cornerRadius: 14))
                    Button("Find") { Task { await findTransfer() } }
                        .disabled(transferCode.count < 4 || isWorking)
                }

                if let transfer {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Customer claims \(transfer.claimed_stamps) stamps. Check their paper card before confirming.")
                            .font(.subheadline)
                        Stepper("Confirm \(confirmCount) stamp\(confirmCount == 1 ? "" : "s")",
                                value: $confirmCount, in: 0...transfer.claimed_stamps)
                        Button {
                            Task { await completeTransfer() }
                        } label: {
                            Label("Confirm transfer", systemImage: "checkmark.seal.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.navy, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }
                        .disabled(isWorking)
                    }
                    .padding()
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
            }
            .background(Theme.cream.ignoresSafeArea())
            .topBanner($message)
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
            pendingCode = nil
            if let found = card {
                let requests: [PendingRequest] = try await supabase
                    .from("redemption_requests")
                    .select("code")
                    .eq("membership_id", value: found.id.uuidString)
                    .eq("status", value: "pending")
                    .gt("expires_at", value: Date().ISO8601Format())
                    .execute()
                    .value
                pendingCode = requests.first?.code
            }
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
    
    private func findTransfer() async {
        do {
            let rows: [PendingTransfer] = try await supabase
                .from("transfer_requests")
                .select("code, claimed_stamps")
                .eq("code", value: transferCode)
                .eq("shop_id", value: shop.shop_id.uuidString)
                .eq("status", value: "pending")
                .gt("expires_at", value: Date().ISO8601Format())
                .execute()
                .value
            transfer = rows.first
            confirmCount = transfer?.claimed_stamps ?? 0
            message = transfer == nil ? "No transfer with that code. It may have expired." : nil
        } catch {
            message = error.localizedDescription
        }
    }

    private func completeTransfer() async {
        isWorking = true
        defer { isWorking = false }
        do {
            let balance: Int = try await supabase
                .rpc("complete_transfer", params: CompleteTransferParams(p_code: transferCode,
                                                                         p_shop_id: shop.shop_id.uuidString,
                                                                         p_confirmed: confirmCount))
                .execute()
                .value
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            message = "Transfer complete. Card balance: \(balance)."
            transfer = nil
            transferCode = ""
        } catch let error as PostgrestError {
            message = error.message
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
