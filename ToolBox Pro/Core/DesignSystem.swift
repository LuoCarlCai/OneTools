import SwiftUI

enum AppColor {
    static let primary = Color(hex: 0x165DFF)
    static let success = Color(hex: 0x36D399)
    static let warning = Color(hex: 0xFB8B24)
    static let background = Color.dynamic(light: 0xF9FAFB, dark: 0x111827)
    static let surface = Color.dynamic(light: 0xFFFFFF, dark: 0x1F2937)
    static let primaryText = Color.dynamic(light: 0x111827, dark: 0xF9FAFB)
    static let secondaryText = Color.dynamic(light: 0x6B7280, dark: 0x9CA3AF)
    static let border = Color.dynamic(light: 0xE5E7EB, dark: 0x374151)
}

extension View {
    func appFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        font(.system(size: size, weight: weight, design: .rounded))
    }

    @ViewBuilder
    func hidesTabBarOnPush() -> some View {
        if #available(iOS 16.0, *) {
            toolbar(.hidden, for: .tabBar)
        } else {
            self
        }
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    static func dynamic(light: UInt, dark: UInt) -> Color {
        Color(UIColor { trait in
            let hex = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}
