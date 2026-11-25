import SwiftUI
import UIKit

// MARK: - Color helpers

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(UIColor(hex: hex))
    }

    /// Color that adapts to the current interface style.
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

// MARK: - Tokens (see docs/DESIGN.md §2)

enum Theme {
    static let bg = Color.adaptive(light: 0xF4F7F3, dark: 0x0D1412)
    static let surface = Color.adaptive(light: 0xFFFFFF, dark: 0x151E1B)
    static let surfaceAlt = Color.adaptive(light: 0xEDF2EC, dark: 0x1C2723)

    static let ink = Color.adaptive(light: 0x1B2320, dark: 0xF2F6F3)
    static let inkSecondary = Color.adaptive(light: 0x6B7A73, dark: 0x9AA8A2)
    static let inkTertiary = Color.adaptive(light: 0xA3AFA9, dark: 0x5E6B66)

    static let mint = Color(hex: 0x6FC79A)
    static let mintSoft = Color.adaptive(light: 0xDDF1E4, dark: 0x1F3A2C)

    static let overload = Color.adaptive(light: 0xE8604C, dark: 0xF0705D)
    static let warn = Color.adaptive(light: 0xE9A13B, dark: 0xF0AE4E)
    static let normal = Color.adaptive(light: 0x58C08D, dark: 0x63CB97)
    static let great = Color.adaptive(light: 0x5C7CFA, dark: 0x7B95FF)
    static let muted = Color.adaptive(light: 0xB9C3BE, dark: 0x4E5A55)

    static let hairline = Color.adaptive(light: 0xE3E9E4, dark: 0x263330)

    // Geometry
    static let pagePadding: CGFloat = 20
    static let cardPadding: CGFloat = 20
    static let cardSpacing: CGFloat = 14
    static let cardRadius: CGFloat = 24
    static let buttonRadius: CGFloat = 16

    static let cardShadow = Color.black.opacity(0.06)
}

// MARK: - Typography

extension Font {
    static let displayNumber = Font.system(size: 56, weight: .bold, design: .rounded)
    static let pageTitle = Font.system(size: 24, weight: .bold, design: .rounded)
    static let cardTitle = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let bodyText = Font.system(size: 15, weight: .regular, design: .rounded)
    static let captionText = Font.system(size: 13, weight: .medium, design: .rounded)
    static let tagText = Font.system(size: 12, weight: .semibold, design: .rounded)
    static let heroNumber = Font.system(size: 40, weight: .bold, design: .rounded)
}

// MARK: - Shared formatting

enum Fmt {
    static let dayMonth: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日"
        return f
    }()

    static let weekday: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "EEEE"
        return f
    }()

    static let hourMinute: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "HH:mm"
        return f
    }()

    static func weekdayShort(_ date: Date) -> String {
        let names = ["日", "一", "二", "三", "四", "五", "六"]
        let idx = Calendar.current.component(.weekday, from: date) - 1
        return "周" + names[max(0, min(6, idx))]
    }
}
