//
//  EditPersonalCardView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI

struct EditPersonalCardView: View {
    let card: LoyaltyCard
    let onFinished: () -> Void          // closes the card sheet too
    @Environment(CardStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var pending = 0
    @State private var swapSides = false
    @State private var confirmDelete = false
    @State private var isWorking = false

    private var shownFront: URL? { swapSides ? card.backImageURL : card.imageURL }
    private var shownBack: URL? { swapSides ? card.imageURL : card.backImageURL }
    private var frontAspect: CGFloat { (swapSides ? card.backImageAspect : card.imageAspect) ?? 1.75 }
    private var backAspect: CGFloat { (swapSides ? card.imageAspect : card.backImageAspect) ?? 1.75 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Front · shows in your stack") {
                    RealCardView(imageURL: shownFront, aspectRatio: frontAspect, title: name)
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                }

                if card.backImageURL != nil {
                    Section("Back") {
                        RealCardView(imageURL: shownBack, aspectRatio: backAspect)
                            .padding(.vertical, 8)
                            .listRowBackground(Color.clear)
                        Button("Swap front and back", systemImage: "arrow.left.arrow.right") {
                            withAnimation(.spring) { swapSides.toggle() }
                        }
                    }
                }

                Section("Details") {
                    TextField("Shop name", text: $name)
                    Stepper("Stamps on your card: \(pending)", value: $pending, in: 0...card.stampsNeeded)
                }

                Section {
                    Button("Delete card", role: .destructive) { confirmDelete = true }
                }
            }
            .navigationTitle("Edit card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isWorking = true
                            await store.updatePersonal(card, name: name, pending: pending, swapSides: swapSides)
                            onFinished()
                        }
                    }
                    .disabled(name.isEmpty || isWorking)
                }
            }
            .confirmationDialog("Delete \(card.shopName)?", isPresented: $confirmDelete,
                                titleVisibility: .visible) {
                Button("Delete card", role: .destructive) {
                    Task {
                        isWorking = true
                        await store.deletePersonal(card)
                        onFinished()
                    }
                }
            } message: {
                Text("This removes the card and its photos. Pending stamps can't be recovered.")
            }
            .onAppear {
                name = card.shopName
                pending = card.stamps
            }
        }
    }
}
