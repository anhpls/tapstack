//
//  Theme.swift
//  Tapstack
//
//  Created by Anh Huynh on 11/25/26.
//

import SwiftUI

enum Theme{
    static let cream  = Color(red: 0.984, green: 0.973, blue: 0.953) // #FBF8F3
    static let navy   = Color(red: 0.122, green: 0.141, blue: 0.200) // #1F2433
    static let accent = Color(red: 0.761, green: 0.341, blue: 0.122) // #C2571F
    // pastel card colors
    static let sky      = Color(red: 0.812, green: 0.878, blue: 0.953) // #CFE0F3
    static let peach    = Color(red: 0.969, green: 0.839, blue: 0.769) // #F7D6C4
    static let butter   = Color(red: 0.965, green: 0.906, blue: 0.706) // #F6E7B4
    static let mint     = Color(red: 0.804, green: 0.910, blue: 0.839) // #CDE8D6
    static let lavender = Color(red: 0.867, green: 0.835, blue: 0.941) // #DDD5F0
    static let sage     = Color(red: 0.851, green: 0.894, blue: 0.800) // #D9E4CC
    static let rose     = Color(red: 0.953, green: 0.820, blue: 0.863) // #F3D1DC
}

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt64(clean, radix: 16) ?? 0
        self.init(
            red:   Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8)  & 0xFF) / 255,
            blue:  Double(value & 0xFF) / 255
        )
    }
}
