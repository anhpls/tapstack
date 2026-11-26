//
//  RealCardView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI

// presents a scanned card like a premium physical card
struct RealCardView: View {
    var image: UIImage? = nil
    var imageURL: URL? = nil
    var aspectRatio: CGFloat = 1.75
    var badge: String? = nil
    var title: String? = nil

//    private let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            face

            // studio lighting: soft sheen top-left, slight shade bottom-right
//            LinearGradient(stops: [
//                .init(color: .white.opacity(0.22), location: 0),
//                .init(color: .white.opacity(0), location: 0.45),
//                .init(color: .black.opacity(0.12), location: 1)
//            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            CardSheen()

            if let title, !title.isEmpty {
                // soft dark fade at the top so the name reads on any artwork
                LinearGradient(colors: [.black.opacity(0.5), .clear],
                               startPoint: .top, endPoint: .init(x: 0.5, y: 0.4))

                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
                    .lineLimit(1)
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            
            if let badge {
                Text(badge)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.45), in: Capsule())
                    .padding(12)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
//        .clipShape(shape)
//        .overlay(shape.strokeBorder(.white.opacity(0.35), lineWidth: 1))      // bright edge
//        .overlay(shape.strokeBorder(.black.opacity(0.12), lineWidth: 0.5))    // crisp outline
//        .shadow(color: .black.opacity(0.10), radius: 2, y: 1)                 // contact shadow
//        .shadow(color: .black.opacity(0.20), radius: 18, y: 12)               // soft lift
        .premiumCard()
    }

    @ViewBuilder private var face: some View {
        if let image {
            Image(uiImage: image).resizable().scaledToFill()
        } else if let imageURL {
            AsyncImage(url: imageURL) { $0.resizable().scaledToFill() } placeholder: {
                Color.gray.opacity(0.15)
            }
        } else {
            Color.gray.opacity(0.15)
        }
    }
}
