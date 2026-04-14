import SwiftUI

struct AppSplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0xFCFCFE), Color(hex: 0xF3F6FB)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(hex: 0xFFE7A8).opacity(0.54))
                .frame(width: 168, height: 168)
                .offset(x: -156, y: -246)

            Circle()
                .fill(Color(hex: 0xBFEFE6).opacity(0.76))
                .frame(width: 176, height: 176)
                .offset(x: 156, y: -226)

            Circle()
                .fill(Color(hex: 0xE7DBFF).opacity(0.44))
                .frame(width: 210, height: 210)
                .offset(x: 122, y: 316)

            Rectangle()
                .fill(Color(hex: 0xFFFFFF).opacity(0.72))
                .frame(width: 1, height: 150)
                .offset(x: -150, y: -78)

            VStack(alignment: .leading, spacing: 20) {
                Text(AppLocalizer.string("ONE DAILY UTILITY SUITE"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: 0x7B8798))
                    .tracking(1.6)

                VStack(alignment: .leading, spacing: 10) {
                    Text(AppLocalizer.string("OneTools"))
                        .appFont(size: 42, weight: .bold)
                        .foregroundColor(Color(hex: 0x0F172A))

                    Text(AppLocalizer.string("Everyday utility tools, refined."))
                        .appFont(size: 17, weight: .medium)
                        .foregroundColor(Color(hex: 0x667085))
                }

                Text(AppLocalizer.string("CALCULATE  CONVERT  SCAN  TRANSCRIBE"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: 0x94A3B8))
                    .tracking(1.4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, 32)
            .padding(.top, 168)
        }
    }
}
