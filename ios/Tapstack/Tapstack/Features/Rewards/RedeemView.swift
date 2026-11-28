//
//  RedeemView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI
import Supabase

struct RedemptionRequest: Decodable {
    let id: UUID
    let code: String
}

struct RequestStatus: Decodable {
    let status: String
}

struct RedeemView: View {
    let card: LoyaltyCard
    @Environment(\.dismiss) private var dismiss

    @State private var request: RedemptionRequest?
    @State private var expiresAt = Date().addingTimeInterval(300)
    @State private var redeemed = false
    @State private var errorMessage: String?
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 24) {
            if redeemed {
                Spacer()
                Text("🎉").font(.system(size: 72))
                Text("Enjoy your \(card.reward)!").font(.title2.bold())
                Text("Your card has started over. Extra stamps carried over.")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
                Spacer()
                Button("Done") { dismiss() }.font(.headline).foregroundStyle(Theme.navy)
            } else if let request {
                Text("Show this to staff").font(.headline).foregroundStyle(.secondary)
                Text(card.reward).font(.largeTitle.bold())
                Text(card.shopName).foregroundStyle(.secondary)

                // the code staff check against their screen
                Text(request.code)
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .tracking(8)

                // live elements: a screenshot can't fake these
                HStack(spacing: 8) {
                    Circle().fill(.green).frame(width: 10, height: 10)
                        .scaleEffect(pulse ? 1.4 : 0.8)
                        .animation(.easeInOut(duration: 0.8).repeatForever(), value: pulse)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let left = max(0, Int(expiresAt.timeIntervalSince(context.date)))
                        Text(left > 0 ? String(format: "Expires in %d:%02d", left / 60, left % 60) : "Expired")
                            .font(.footnote.monospacedDigit())
                    }
                }
                .foregroundStyle(.secondary)

                BarcodeView(value: card.memberNumber)
                    .padding()
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))

                Spacer()
                Button("Cancel") { dismiss() }.foregroundStyle(.secondary)
            } else if let errorMessage {
                Spacer()
                Text(errorMessage).foregroundStyle(.red)
                Button("Close") { dismiss() }
                Spacer()
            } else {
                ProgressView()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.cream.ignoresSafeArea())
        .task { await start() }
    }

    private func start() async {
        do {
            let rows: [RedemptionRequest] = try await supabase
                .rpc("request_redemption", params: ["p_membership_id": card.id.uuidString])
                .execute()
                .value
            request = rows.first
            expiresAt = Date().addingTimeInterval(300)
            pulse = true
            await waitForStaff()
        } catch let error as PostgrestError {
            // DEBUG (remove-card bug): which card did the database reject?
            print("DEBUG redeem failed | card \(card.id) | shop \(card.shopName) | \(error.message)")
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // checks every 3 seconds until staff confirm or the screen closes
    private func waitForStaff() async {
        guard let id = request?.id else { return }
        while !Task.isCancelled && Date() < expiresAt {
            try? await Task.sleep(for: .seconds(3))
            let rows: [RequestStatus] = (try? await supabase
                .from("redemption_requests")
                .select("status")
                .eq("id", value: id.uuidString)
                .execute()
                .value) ?? []
            if rows.first?.status == "redeemed" {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring) { redeemed = true }
                return
            }
        }
    }
}
