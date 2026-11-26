//
//  DesignedCardView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI

struct DesignedCardView: View {
    let design: CardDesign
    let title: String
    var artwork: UIImage? = nil        // the scanned front, used by "art" style
    var artworkURL: URL? = nil         // same, after saving
    var logo: UIImage? = nil
    var logoURL: URL? = nil
    let stamps: Int
    let stampsNeeded: Int
    var pending = true

    private var accent: Color { Color(hex: design.accentHex) }
    private var slot: Color { Color(hex: design.slotHex) }
    private var foreground: Color { Color(hex: design.textHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.title3.bold()).lineLimit(1)
                    if let subtitle = design.subtitle {
                        Text(subtitle).font(.caption).opacity(0.85).lineLimit(2)
                    }
                }
                Spacer()
                logoView.frame(width: 56, height: 56)
            }

            // stamp slots styled like the card: light circle, vivid "seal" when stamped
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8),
                                     count: min(stampsNeeded, 5)),
                      spacing: 8) {
                ForEach(0..<stampsNeeded, id: \.self) { i in
                    ZStack {
                        Circle().fill(slot.opacity(0.9))
                        if i < stamps {
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(accent, lineWidth: 2.5)
                                .padding(6)
                                .rotationEffect(.degrees(-12))
                                .opacity(pending ? 0.6 : 1)
                        }
                    }
                    .frame(height: 30)
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                }
            }

            if pending {
                Text("Not verified · \(stamps) pending")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .foregroundStyle(foreground)
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .background { backgroundView }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    @ViewBuilder private var backgroundView: some View {
        ZStack {
            Color(hex: design.backgroundHex)
            if design.style == "art" {
                Group {
                    if let artwork {
                        Image(uiImage: artwork).resizable().scaledToFill()
                    } else if let artworkURL {
                        AsyncImage(url: artworkURL) { $0.resizable().scaledToFill() } placeholder: { Color.clear }
                    }
                }
                .blur(radius: 3)                       // soften the painting so the UI stays crisp
                LinearGradient(colors: [.black.opacity(0.55), .black.opacity(0.15), .black.opacity(0.45)],
                               startPoint: .top, endPoint: .bottom)
            }
        }
    }

    @ViewBuilder private var logoView: some View {
        if let logo {
            Image(uiImage: logo).resizable().scaledToFit()
        } else if let logoURL {
            AsyncImage(url: logoURL) { $0.resizable().scaledToFit() } placeholder: { Color.clear }
        }
    }
}
