//
//  ImageEnhancer.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// makes a phone scan look like a clean print
nonisolated enum ImageEnhancer {
    static func enhance(_ image: UIImage) -> UIImage {
        let upright = normalized(image)
        guard var ci = CIImage(image: upright) else { return upright }

        // Apple's automatic exposure, color and contrast fixes
        for filter in ci.autoAdjustmentFilters(options: [.redEye: false]) {
            filter.setValue(ci, forKey: kCIInputImageKey)
            if let out = filter.outputImage { ci = out }
        }

        let vibrance = CIFilter.vibrance()
        vibrance.inputImage = ci
        vibrance.amount = 0.2
        ci = vibrance.outputImage ?? ci

        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = ci
        sharpen.sharpness = 0.4
        ci = sharpen.outputImage ?? ci

        guard let cg = CIContext().createCGImage(ci, from: ci.extent) else { return upright }
        return UIImage(cgImage: cg)
    }

    // photos can be stored sideways with a "rotate me" flag; this bakes the rotation in
    static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        return UIGraphicsImageRenderer(size: image.size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
