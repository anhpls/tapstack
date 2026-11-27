//
//  TopBanner.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI

// a message banner that slides down from the top, then hides itself
struct TopBanner: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message {
                    Text(message)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.navy, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                        .padding(.horizontal)
                        .padding(.top, 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture { self.message = nil }      // tap to dismiss early
                }
            }
            .animation(.spring(duration: 0.35), value: message)
            .task(id: message) {
                // auto-hide after 3 seconds
                guard message != nil else { return }
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }           // a newer message replaced it
                message = nil
            }
    }
}

extension View {
    func topBanner(_ message: Binding<String?>) -> some View {
        modifier(TopBanner(message: message))
    }
}
