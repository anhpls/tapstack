//
//  RootView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI
import Supabase

struct RootView: View {
    @State private var isSignedIn = false

    var body: some View {
        Group {
            if isSignedIn {
                ContentView()
            } else {
                SignInView()
            }
        }
        .task {
            for await (_, session) in supabase.auth.authStateChanges {
                isSignedIn = (session != nil)
            }
        }
    }
}
