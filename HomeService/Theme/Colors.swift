import SwiftUI

extension Color {
    // MARK: - Primary (Teal)
    static let hbPrimary = Color(hex: "14B8A6")
    static let hbPrimaryDark = Color(hex: "0D9488")
    static let hbPrimaryLight = Color(hex: "CCFBF1")

    // MARK: - Complementary Accents
    static let hbCoral = Color(hex: "F28B82")
    static let hbLavender = Color(hex: "A78BFA")
    static let hbAmber = Color(hex: "FBBF24")
    static let hbSky = Color(hex: "38BDF8")
    static let hbRose = Color(hex: "FB7185")

    // MARK: - Background (Warm peach/tan)
    static let hbBackground = Color(hex: "FFFAF5")
    static let hbBackgroundEnd = Color(hex: "FFF7F0")
    static let hbSurface = Color.white
    static let hbSurfaceWarm = Color(hex: "FFF3EA")
    static let hbSurfaceMint = Color(hex: "F0FAF7")

    // MARK: - Text
    static let hbTextPrimary = Color(hex: "1E293B")
    static let hbTextSecondary = Color(hex: "64748B")

    // MARK: - Border
    static let hbBorder = Color(hex: "E8E0D8")

    // MARK: - Categories
    static let hbPlumbing = Color(hex: "38BDF8")
    static let hbElectrical = Color(hex: "FBBF24")
    static let hbHVAC = Color(hex: "A78BFA")
    static let hbExterior = Color(hex: "34D399")
    static let hbAppliance = Color(hex: "FB7185")
    static let hbStructural = Color(hex: "818CF8")

    // MARK: - Semantic
    static let hbSuccess = Color(hex: "34D399")
    static let hbWarning = Color(hex: "FBBF24")
    static let hbDanger = Color(hex: "FB7185")

    static func healthScoreColor(for score: Int) -> Color {
        if score >= 80 { return .hbSuccess }
        if score >= 60 { return .hbWarning }
        return .hbDanger
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
