//
//  CardAnalyzer.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI
import Vision
import CoreImage

// the "recipe" for drawing a designed card
struct CardDesign: Codable, Equatable {
    var style: String          // "art" = painted background, "flat" = solid colors
    var backgroundHex: String  // main color
    var accentHex: String      // the card's most vivid color (stamps)
    var slotHex: String        // the card's lightest color (empty stamp circles)
    var textHex: String
    var subtitle: String?      // rules text, if found
}

struct CardAnalysis {
    var design: CardDesign
    var logo: UIImage?
    var stampSlots: Int?
}

nonisolated enum CardAnalyzer {

    static func analyze(front: UIImage, back: UIImage?) -> CardAnalysis {
        let px = samplePixels(front)
        guard !px.isEmpty else {
            return CardAnalysis(design: CardDesign(style: "flat", backgroundHex: "#1F2433",
                                                   accentHex: "#C2571F", slotHex: "#FFFFFF",
                                                   textHex: "#FFFFFF", subtitle: nil),
                                logo: nil, stampSlots: nil)
        }

        // background = average color of the whole card
        let average = px.reduce(SIMD3<Double>(0, 0, 0), +) / Double(px.count)

        // accent = average of the most vivid 5% of pixels (red seals, logo color...)
        let vivid = px.sorted { vividness($0) > vividness($1) }.prefix(max(1, px.count / 20))
        let accent = vivid.reduce(SIMD3<Double>(0, 0, 0), +) / Double(vivid.count)

        // slot = average of the lightest 5% (white circles, paper color...)
        let light = px.sorted { brightness($0) > brightness($1) }.prefix(max(1, px.count / 20))
        let slot = light.reduce(SIMD3<Double>(0, 0, 0), +) / Double(light.count)

        // busy, painterly card? use its artwork as the background
        let busyness = px.map { distance($0, average) }.reduce(0, +) / Double(px.count)
        let style = busyness > 0.16 ? "art" : "flat"

        let text = (style == "art" || brightness(average) < 0.55)
            ? SIMD3<Double>(1, 1, 1)
            : SIMD3<Double>(0.122, 0.141, 0.2)

        // rules text (English or Asian scripts), front and back
        var lines = readText(front)
        if let back { lines += readText(back) }
        let rules = lines.first { line in
            let l = line.lowercased()
            return ["free", "stamp", "buy", "get", "drink", "reward", "集", "送", "免费"].contains { l.contains($0) }
        }

        return CardAnalysis(
            design: CardDesign(style: style,
                               backgroundHex: hex(average),
                               accentHex: hex(accent),
                               slotHex: hex(slot),
                               textHex: hex(text),
                               subtitle: rules),
            logo: style == "flat" ? liftLogo(from: front) : nil,   // art cards carry their own identity
            stampSlots: stampCount(from: rules)
        )
    }

    // MARK: pixels

    // shrinks the card to 48×30 and reads every pixel's color (0–1)
    static func samplePixels(_ image: UIImage) -> [SIMD3<Double>] {
        guard let cg = image.cgImage else { return [] }
        let w = 48, h = 30
        var data = [UInt8](repeating: 0, count: w * h * 4)
        data.withUnsafeMutableBytes { buffer in
            guard let ctx = CGContext(data: buffer.baseAddress, width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        return stride(from: 0, to: data.count, by: 4).map {
            SIMD3(Double(data[$0]) / 255, Double(data[$0 + 1]) / 255, Double(data[$0 + 2]) / 255)
        }
    }

    static func brightness(_ c: SIMD3<Double>) -> Double { 0.299 * c.x + 0.587 * c.y + 0.114 * c.z }

    // saturated AND bright = vivid
    static func vividness(_ c: SIMD3<Double>) -> Double {
        let maxC = max(c.x, c.y, c.z), minC = min(c.x, c.y, c.z)
        return (maxC - minC) * maxC
    }

    static func distance(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
        let d = a - b
        return (d * d).sum().squareRoot()
    }

    static func hex(_ c: SIMD3<Double>) -> String {
        String(format: "#%02X%02X%02X",
               Int((c.x * 255).rounded()), Int((c.y * 255).rounded()), Int((c.z * 255).rounded()))
    }

    // MARK: text

    static func readText(_ image: UIImage) -> [String] {
        guard let cg = image.cgImage else { return [] }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true
        request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant", "ja-JP", "ko-KR"]
        try? VNImageRequestHandler(cgImage: cg).perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
    }

    // "Buy 9 get 1 free" → 10, "Collect 8 stamps" → 8
    static func stampCount(from rules: String?) -> Int? {
        guard let rules else { return nil }
        let numbers = rules.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard let first = numbers.first else { return nil }
        let lower = rules.lowercased()
        let total = (lower.contains("buy") && lower.contains("get") && numbers.count > 1)
            ? first + numbers[1] : first
        return (3...30).contains(total) ? total : nil
    }

    // MARK: logo (flat cards only)

    static func liftLogo(from image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let handler = VNImageRequestHandler(cgImage: cg)
        let area = CGFloat(cg.width * cg.height)
        let request = VNGenerateForegroundInstanceMaskRequest()
        guard (try? handler.perform([request])) != nil,
              let result = request.results?.first,
              let buffer = try? result.generateMaskedImage(ofInstances: result.allInstances,
                                                           from: handler,
                                                           croppedToInstancesExtent: true) else { return nil }
        let ci = CIImage(cvPixelBuffer: buffer)
        let share = ci.extent.width * ci.extent.height / area
        // a real logo is a part of the card: not almost nothing, not almost everything
        guard share > 0.03, share < 0.6,
              let out = CIContext().createCGImage(ci, from: ci.extent) else { return nil }
        return UIImage(cgImage: out)
    }
}
