//
//  SignInView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//
import SwiftUI
import Supabase

struct SignInView: View {
    @State private var email = ""
    @State private var code = ""
    @State private var codeSent = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()

            HStack(spacing: 0) {
                Text("tap").fontWeight(.bold)
                Text("stack").foregroundStyle(.secondary)
            }
            .font(.largeTitle)

            Text(codeSent ? "Enter the code we emailed you." : "Every reward, in one tap.")
                .foregroundStyle(.secondary)

            if !codeSent {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))

                primaryButton("Send code") { await sendCode() }
                    .disabled(email.isEmpty || isLoading)
            } else {
                TextField("123456", text: $code)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))

                primaryButton("Sign in") { await verifyCode() }
                    .disabled(code.count < 6 || isLoading)

                Button("Use a different email") {
                    codeSent = false
                    code = ""
                }
                .font(.footnote)
                .foregroundStyle(Theme.navy)
            }

            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }

            Spacer()
        }
        .padding(24)
        .background(Theme.cream.ignoresSafeArea())
    }

    private func primaryButton(_ title: String, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            Text(isLoading ? "Please wait…" : title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.navy, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
    }

    private func sendCode() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await supabase.auth.signInWithOTP(email: email)
            codeSent = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func verifyCode() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await supabase.auth.verifyOTP(email: email, token: code, type: .email)
        } catch {
            errorMessage = "That code didn't work. Check it and try again."
        }
    }
}

#Preview {
    SignInView()
}
