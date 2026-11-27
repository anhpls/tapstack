//
//  AddPersonalCardView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI
import PhotosUI
import VisionKit
import Supabase

struct NewPersonalCard: Encodable {
    let shop_name: String
    let category: String
    let stamps_needed: Int
    let pending_stamps: Int
    let image_path: String?
    let image_back_path: String?
    let image_aspect: Double?
    let image_back_aspect: Double?
}

struct AddPersonalCardView: View {
    let store: CardStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var rawFront: UIImage?        // original scans
    @State private var rawBack: UIImage?
    @State private var front: UIImage?          // shows in your stack
    @State private var back: UIImage?
    @State private var autoEnhance = true
    @State private var scanTarget: ScanTarget = .both
    @State private var showingScanner = false
    @State private var photoItem: PhotosPickerItem?
    @State private var isPolishing = false
    @State private var shopName = ""
    @State private var category: ShopCategory = .boba
    @State private var stampsNeeded = 10
    @State private var stampsOnCard = 0
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    enum ScanTarget { case both, front, back }
    
    private var aspect: CGFloat {
        guard let front, front.size.height > 0 else { return 1.75 }
        return front.size.width / front.size.height
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if isPolishing {
                        HStack { ProgressView(); Text("Polishing your card…") }
                    } else if let front {
                        RealCardView(image: front, aspectRatio: aspect,
                                     badge: "Not verified · \(stampsOnCard) pending", title: shopName)
                        .padding(.vertical, 12)
                        .listRowBackground(Color.clear)
                        Button("Retake this side", systemImage: "camera") {
                            scanTarget = .front
                            showingScanner = true
                        }
                        
                        if let back {
                            RealCardView(image: back, aspectRatio: back.size.width / back.size.height)
                                .padding(.vertical, 12)
                                .listRowBackground(Color.clear)
                            Button("Retake this side", systemImage: "camera") {
                                scanTarget = .back
                                showingScanner = true
                            }
                            Button("Swap front and back", systemImage: "arrow.left.arrow.right") {
                                withAnimation(.spring) {
                                    swap(&rawFront, &rawBack)
                                    swap(&self.front, &self.back)
                                }
                            }
                        }
                        
                        Toggle("Auto-enhance", isOn: $autoEnhance)
                            .onChange(of: autoEnhance) { polish() }
                    }
                    
                    if front == nil {
                        if VNDocumentCameraViewController.isSupported {
                            Button("Scan your card") {
                                scanTarget = .both
                                showingScanner = true
                            }
                            Text("Scan the side you want in your stack first, then flip it and scan the other side. Turn off the flash for glossy cards.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            PhotosPicker("Choose a photo of your card", selection: $photoItem, matching: .images)
                        }
                    }
                }
                
                Section("About the card") {
                    TextField("Shop name, like YunTea", text: $shopName)
                    Picker("Category", selection: $category) {
                        ForEach(ShopCategory.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    Stepper("Stamps for a reward: \(stampsNeeded)", value: $stampsNeeded, in: 1...30)
                    Stepper("Stamps on your card: \(stampsOnCard)", value: $stampsOnCard, in: 0...stampsNeeded)
                }
                
                Section {
                    Text("These stamps stay pending until \(shopName.isEmpty ? "the shop" : shopName) confirms them at the counter.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Add your own card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                        .disabled(shopName.isEmpty || front == nil || isSaving)
                }
            }
            .fullScreenCover(isPresented: $showingScanner) {
                CardScannerView { pages in
                    switch scanTarget {
                    case .both:
                        rawFront = pages.first
                        rawBack = pages.count > 1 ? pages[1] : nil
                    case .front:
                        rawFront = pages.first ?? rawFront
                    case .back:
                        rawBack = pages.first ?? rawBack
                    }
                    polish()
                }
                .ignoresSafeArea()
            }
            .onChange(of: photoItem) {
                Task {
                    if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                        rawFront = UIImage(data: data)
                        polish()
                    }
                }
            }
        }
    }
    // builds the shown images from the original scans (enhanced or not)
    private func polish() {
        guard let rawFront else { return }
        let rawBack = rawBack
        guard autoEnhance else {
            front = ImageEnhancer.normalized(rawFront)
            back = rawBack.map { ImageEnhancer.normalized($0) }
            return
        }
        isPolishing = true
        Task {
            let result = await Task.detached {
                (ImageEnhancer.enhance(rawFront), rawBack.map { ImageEnhancer.enhance($0) })
            }.value
            front = result.0
            back = result.1
            isPolishing = false
        }
    }
    private func save() async {
        guard let front, let frontJpeg = front.jpegData(compressionQuality: 0.9) else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let userID = try await supabase.auth.session.user.id
            let folder = userID.uuidString.lowercased()   // must match the storage policy
            
            let frontPath = "\(folder)/\(UUID().uuidString).jpg"
            try await supabase.storage
                .from("card-images")
                .upload(frontPath, data: frontJpeg, options: FileOptions(contentType: "image/jpeg"))
            
            var backPath: String?
            if let back, let backJpeg = back.jpegData(compressionQuality: 0.9) {
                let p = "\(folder)/\(UUID().uuidString)-back.jpg"
                try await supabase.storage
                    .from("card-images")
                    .upload(p, data: backJpeg, options: FileOptions(contentType: "image/jpeg"))
                backPath = p
            }
            
            try await supabase
                .from("personal_cards")
                .insert(NewPersonalCard(shop_name: shopName,
                                        category: category.rawValue,
                                        stamps_needed: stampsNeeded,
                                        pending_stamps: stampsOnCard,
                                        image_path: frontPath,
                                        image_back_path: backPath,
                                        image_aspect: Double(aspect),
                                        image_back_aspect: back.map { Double($0.size.width / $0.size.height) }))
                .execute()
            
            await store.load()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
