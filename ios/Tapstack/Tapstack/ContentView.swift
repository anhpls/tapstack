//
//  ContentView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            CardStackView(cards: LoyaltyCard.samples)
                .navigationTitle("Tapstack")
        }
    }
}

#Preview {
    ContentView()
}
