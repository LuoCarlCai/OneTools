import SwiftUI

struct AppSplashView: View {
    var body: some View {
        ZStack {
            Color(hex: 0xFBFCFE).ignoresSafeArea()

            Circle()
                .fill(Color(hex: 0xFEE58F).opacity(0.48))
                .frame(width: 144, height: 144)
                .offset(x: -156, y: -250)

            Circle()
                .fill(Color(hex: 0xBEF3DE).opacity(0.5))
                .frame(width: 154, height: 154)
                .offset(x: 142, y: -262)

            Circle()
                .fill(Color(hex: 0xF9D8E8).opacity(0.28))
                .frame(width: 190, height: 190)
                .offset(x: 146, y: 308)

            VStack(alignment: .leading, spacing: 18) {
                Text(AppLocalizer.string("OneTools"))
                    .appFont(size: 38, weight: .bold)
                    .foregroundColor(Color(hex: 0x111827))

                Text(AppLocalizer.string("Everyday utilities, instantly."))
                    .appFont(size: 18, weight: .medium)
                    .foregroundColor(Color(hex: 0x6B7280))

                Text("ALL-IN-ONE UTILITIES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: 0x6B7280).opacity(0.8))
                    .tracking(1.2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, 24)
            .padding(.top, 154)
        }
    }
}
