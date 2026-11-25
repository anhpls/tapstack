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

struct BusinessHomeView: View {
    let shop: ShopRole
    let onExit: () -> Void

    @State private var memberNumber = ""
    @State private var card: LoyaltyCard?
    @State private var message: String?
    @State private var isWorking = false
    @State private var count = 1

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
                    .disabled(isWorking)
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
                .select("id, member_number, shops(id, name, category, color_hex, stamp_programs(stamps_needed, reward)), stamps(count)")
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
}
