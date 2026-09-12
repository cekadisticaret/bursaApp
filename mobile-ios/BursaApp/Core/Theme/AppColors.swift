import SwiftUI

enum AppColors {
    // FireVibe brief — #1B4332 primary
    static let nav = Color(red: 27 / 255, green: 67 / 255, blue: 50 / 255)
    static let bg = Color(red: 250 / 255, green: 250 / 255, blue: 251 / 255)
    static let bgSoft = Color(red: 245 / 255, green: 246 / 255, blue: 248 / 255)
    static let bgDeep = nav
    static let card = Color.white
    static let ink = Color(red: 20 / 255, green: 26 / 255, blue: 31 / 255)
    static let muted = Color(red: 133 / 255, green: 138 / 255, blue: 148 / 255)
    static let accent = Color(red: 237 / 255, green: 224 / 255, blue: 204 / 255)
    static let accentDeep = nav
    static let lime = nav
    static let coral = Color(red: 0.95, green: 0.35, blue: 0.35)
    static let amber = Color(red: 1.0, green: 0.78, blue: 0.20)
    static let welcomeBg = bg
    static let sky = nav
    static let pink = Color(red: 0.95, green: 0.55, blue: 0.60)
    static let peach = accent
    static let chipBg = Color.white
    static let chipSelected = accent
}

enum AppRadii {
    static let sm: CGFloat = 16
    static let md: CGFloat = 22
    static let lg: CGFloat = 28
    static let xl: CGFloat = 32
}
