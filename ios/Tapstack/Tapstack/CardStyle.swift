//
//  CardStyle.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI

// the shared "premium physical card" finish: sheen, edges, shadow
struct PremiumCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .clipShape(shape)
            .overlay(shape.strokeBorder(.white.opacity(0.35), lineWidth: 1))      // bright edge
            .overlay(shape.strokeBorder(.black.opacity(0.12), lineWidth: 0.5))    // crisp outline
            .shadow(color: .black.opacity(0.10), radius: 2, y: 1)                 // contact shadow
            .shadow(color: .black.opacity(0.20), radius: 18, y: 12)               // soft lift
    }
}

extension View {
    func premiumCard(cornerRadius: CGFloat = 18) -> some View {
        modifier(PremiumCardStyle(cornerRadius: cornerRadius))
    }
}

// studio lighting: soft highlight top-left, slight shade bottom-right
struct CardSheen: View {
    var body: some View {
        LinearGradient(stops: [
            .init(color: .white.opacity(0.22), location: 0),
            .init(color: .white.opacity(0), location: 0.45),
            .init(color: .black.opacity(0.12), location: 1)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
        .allowsHitTesting(false)
    }
}

// fine chevron lines, like premium metal cards
struct ChevronPattern: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            let spacing: CGFloat = 9
            var x = size.width * 0.38
            while x < size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + size.height * 0.5, y: size.height * 0.5))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            context.stroke(path, with: .color(.white.opacity(0.13)), lineWidth: 0.6)
        }
        .allowsHitTesting(false)
    }
}

extension Color {
    // true when white text reads better than dark text
    var isDark: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (0.299 * r + 0.587 * g + 0.114 * b) < 0.6
    }
}
