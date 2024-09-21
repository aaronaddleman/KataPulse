//
//  AppleSignInView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import SwiftUI
import AuthenticationServices

struct AppleSignInView: View {
    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            // Handle sign-in request
        } onCompletion: { result in
            // Handle sign-in result
        }
        .frame(width: 280, height: 45)
        .signInWithAppleButtonStyle(.black)
    }
}

#Preview {
    AppleSignInView()
}
