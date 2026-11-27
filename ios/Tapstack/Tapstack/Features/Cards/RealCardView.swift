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


    var body: some View {
        ZStack(alignment: .bottomLeading) {
            face
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
