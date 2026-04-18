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

struct AppPageBackground: View {
    let primaryTint: Color
    let secondaryTint: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.dynamic(light: 0xFCFCFE, dark: 0x0F172A),
                    Color.dynamic(light: 0xF5F8FC, dark: 0x111827)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(primaryTint.opacity(0.08))
                .frame(width: 280, height: 220)
                .rotationEffect(.degrees(-12))
                .blur(radius: 2)
                .offset(x: -120, y: -300)

            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(secondaryTint.opacity(0.08))
                .frame(width: 240, height: 200)
                .rotationEffect(.degrees(18))
                .blur(radius: 2)
                .offset(x: 150, y: -210)

            RoundedRectangle(cornerRadius: 56, style: .continuous)
                .fill(primaryTint.opacity(0.04))
                .frame(width: 320, height: 260)
                .rotationEffect(.degrees(20))
                .offset(x: 170, y: 360)
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func appFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        font(.system(size: size, weight: weight, design: .rounded))
    }

    func feedbackOnTap(_ trigger: AppFeedbackTrigger = .selection) -> some View {
        simultaneousGesture(
            TapGesture().onEnded {
                switch trigger {
                case .selection:
                    AppFeedback.selection()
                case .action:
                    AppFeedback.action()
                case .success:
                    AppFeedback.success()
                }
            }
        )
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

enum AppFeedbackTrigger {
    case selection
    case action
    case success
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

struct TrialUsageBanner: View {
    let remainingUses: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .foregroundColor(AppColor.warning)

            VStack(alignment: .leading, spacing: 4) {
                Text(AppLocalizer.string("Free Trial"))
                    .appFont(size: 14, weight: .bold)
                    .foregroundColor(AppColor.primaryText)
                Text(AppLocalizer.string("%@ free uses left", "\(remainingUses)"))
                    .appFont(size: 13, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
            }

            Spacer()
        }
        .padding(14)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }
}

struct FeatureLockedCard: View {
    let feature: PremiumFeature

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppColor.primary.opacity(0.14))
                    .frame(width: 52, height: 52)
                Image(systemName: "lock.fill")
                    .foregroundColor(AppColor.primary)
            }

            Text(AppLocalizer.string("%@ is now part of Pro", feature.title))
                .appFont(size: 22, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            // Purchase-related copy is temporarily hidden.
            Text(AppLocalizer.string("This tool is currently unavailable in this build."))
                .appFont(size: 15, weight: .regular)
                .foregroundColor(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            // In-app purchase button is temporarily hidden.
            // NavigationLink(destination: PaywallView().hidesTabBarOnPush()) {
            //     Text(AppLocalizer.string("Unlock Pro"))
            //         .appFont(size: 16, weight: .bold)
            //         .foregroundColor(.white)
            //         .frame(maxWidth: .infinity)
            //         .padding(.vertical, 14)
            //         .background(AppColor.primary)
            //         .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            // }
            // .buttonStyle(.plain)
        }
        .padding(20)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }
}
