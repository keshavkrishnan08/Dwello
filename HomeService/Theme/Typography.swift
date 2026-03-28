import SwiftUI

struct HBTypography {
    // SF Pro Display — used for headings and display text
    // SF Pro Text — used for body, captions, buttons, chips

    // Display / Hero — SF Pro Display, Bold 700, 28–32pt
    static let display = Font.custom("SFProDisplay-Bold", size: 30, relativeTo: .largeTitle)
    // H1 / Screen Title — SF Pro Display, Bold 700, 24–26pt
    static let h1 = Font.custom("SFProDisplay-Bold", size: 25, relativeTo: .title)
    // H2 / Section — SF Pro Display, Semibold 600, 20pt
    static let h2 = Font.custom("SFProDisplay-Semibold", size: 20, relativeTo: .title2)
    // Body — SF Pro Text, Regular 400, 16–17pt
    static let body = Font.custom("SFProText-Regular", size: 16, relativeTo: .body)
    static let bodyLarge = Font.custom("SFProText-Regular", size: 17, relativeTo: .body)
    // Body Small — SF Pro Text, Regular 400, 14pt
    static let bodySmall = Font.custom("SFProText-Regular", size: 14, relativeTo: .subheadline)
    // Caption — SF Pro Text, Medium 500, 12pt
    static let caption = Font.custom("SFProText-Medium", size: 12, relativeTo: .caption)
    // Button — SF Pro Text, Semibold 600, 17pt
    static let button = Font.custom("SFProText-Semibold", size: 17, relativeTo: .body)
    // Chip / Tag — SF Pro Text, Medium 500, 15pt
    static let chip = Font.custom("SFProText-Medium", size: 15, relativeTo: .subheadline)
    // Stat number — SF Pro Display, Bold, rounded for numerics
    static let statNumber = Font.system(size: 36, weight: .bold, design: .rounded)
    // Small stat — SF Pro Display, Bold, rounded
    static let statSmall = Font.system(size: 22, weight: .bold, design: .rounded)

    // Fallback approach — on iOS, SF Pro is the system font,
    // so Font.custom will resolve to system SF Pro variants.
    // If SF Pro is unavailable (simulator edge case), SwiftUI falls
    // back to the system font which is SF Pro on Apple platforms.
}
