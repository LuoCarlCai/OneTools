import SwiftUI

struct AppSplashView: View {
    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Image("LaunchArtwork")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: .black.opacity(0.16), radius: 20, x: 0, y: 14)

                VStack(spacing: 10) {
                    Text(AppLocalizer.string("OneTools"))
                        .appFont(size: 22, weight: .bold)
                        .foregroundColor(AppColor.primaryText)

                    Text(AppLocalizer.string("Everyday utilities, instantly."))
                        .appFont(size: 16, weight: .medium)
                        .foregroundColor(AppColor.secondaryText)
                }

                HStack(spacing: 10) {
                    splashBadge(title: AppLocalizer.string("Fast"), tint: AppColor.primary)
                    splashBadge(title: AppLocalizer.string("Private"), tint: AppColor.success)
                    splashBadge(title: AppLocalizer.string("Global"), tint: AppColor.warning)
                }
            }
            .padding(28)
        }
    }

    private func splashBadge(title: String, tint: Color) -> some View {
        Text(title)
            .appFont(size: 13, weight: .bold)
            .foregroundColor(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(0.14))
            .clipShape(Capsule())
    }
}
