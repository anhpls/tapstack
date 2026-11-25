//
//  BarcodeView.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct BarcodeView: View {
    let value: String

    var body: some View {
        if let image = Self.makeBarcode(from: value) {
            Image(uiImage: image)
                .interpolation(.none)   // keeps bars sharp
                .resizable()
                .frame(height: 90)
        }
    }

    static func makeBarcode(from value: String) -> UIImage? {
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = Data(value.utf8)
        filter.quietSpace = 8
        guard let output = filter.outputImage,
              let cgImage = CIContext().createCGImage(output, from: output.extent)
        else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    BarcodeView(value: "TS-881902").padding()
}
