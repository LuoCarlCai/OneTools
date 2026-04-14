import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var purchaseStore: PurchaseStore
    @AppStorage("calculatorHistory") private var calculatorHistory = ""
    @AppStorage("voiceToTextHistory") private var voiceToTextHistory = ""

    private let columns = [
        GridItem(.flexible(), spacing: 14, alignment: .top),
        GridItem(.flexible(), spacing: 14, alignment: .top)
    ]

    private var tools: [ToolItem] { ToolItem.all }
    private var latestCalculation: TaggedHistoryRecord? { HistoryStorage.loadRecords(from: calculatorHistory).first }
    private var latestTranscript: TaggedHistoryRecord? { HistoryStorage.loadRecords(from: voiceToTextHistory).first }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    VStack(alignment: .leading, spacing: 14) {
                        featuredStrip

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(tools) { tool in
                                NavigationLink(destination: ToolDestinationView(tool: tool).hidesTabBarOnPush()) {
                                    ToolTile(tool: tool)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    recentActivitySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(AppLocalizer.string("Tools"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: PaywallView().hidesTabBarOnPush()) {
                    Text(purchaseStore.isProUnlocked ? AppLocalizer.string("Pro") : AppLocalizer.string("Remove Ads"))
                        .appFont(size: 14, weight: .bold)
                        .foregroundColor(purchaseStore.isProUnlocked ? AppColor.success : AppColor.primary)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text(AppLocalizer.string("OneTools"))
                    .appFont(size: 22, weight: .bold)
                    .foregroundColor(AppColor.primaryText)

                Text(AppLocalizer.string("Calculate, convert, scan, watermark, compress, and transcribe in one clean workspace."))
                    .appFont(size: 16, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    BadgeView(title: AppLocalizer.string("Fast"), color: AppColor.primary)
                    BadgeView(title: AppLocalizer.string("Private"), color: AppColor.success)
                    BadgeView(title: AppLocalizer.string("Global"), color: AppColor.warning)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppColor.border, lineWidth: 1)
            )

            quickStats
        }
    }

    private var featuredStrip: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppLocalizer.string("Start Here"))
                .appFont(size: 18, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            HStack(spacing: 14) {
                NavigationLink(destination: QRCodeToolView(initialMode: .scan).hidesTabBarOnPush()) {
                    featuredCard(
                        title: AppLocalizer.string("Quick Scan"),
                        detail: AppLocalizer.string("Open QR Toolkit to scan links, Wi-Fi, and notes in seconds."),
                        symbol: "qrcode.viewfinder",
                        tint: AppColor.warning
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: PaywallView().hidesTabBarOnPush()) {
                    featuredCard(
                        title: purchaseStore.isProUnlocked ? AppLocalizer.string("Pro Ready") : AppLocalizer.string("Unlock Pro"),
                        detail: purchaseStore.isProUnlocked
                            ? AppLocalizer.string("Your tools stay clean and ad-free across devices.")
                            : AppLocalizer.string("Monthly Pro restores on your new device with the same Apple ID while active."),
                        symbol: purchaseStore.isProUnlocked ? "checkmark.seal.fill" : "sparkles",
                        tint: purchaseStore.isProUnlocked ? AppColor.success : AppColor.primary
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppLocalizer.string("Recent Activity"))
                .appFont(size: 18, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            if let calc = latestCalculation, !calc.text.isEmpty {
                RecentActivityCard(title: AppLocalizer.string("Last Calculation"), value: calc.text, color: AppColor.primary, symbol: "plus.forwardslash.minus")
            }

            if let transcript = latestTranscript, !transcript.text.isEmpty {
                RecentActivityCard(title: AppLocalizer.string("Last Transcript"), value: transcript.text, color: AppColor.success, symbol: "waveform")
            }

            if latestCalculation == nil && latestTranscript == nil {
                Text(AppLocalizer.string("Your latest calculations and transcripts will show up here."))
                    .appFont(size: 14, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var quickStats: some View {
        HStack(spacing: 12) {
            summaryCard(title: AppLocalizer.string("Tools"), value: "\(tools.count)", tint: AppColor.primary)
            summaryCard(title: AppLocalizer.string("Ready Offline"), value: AppLocalizer.string("Yes"), tint: AppColor.success)
            summaryCard(title: AppLocalizer.string("Languages"), value: "8", tint: AppColor.warning)
        }
    }

    private func summaryCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .appFont(size: 13, weight: .medium)
                .foregroundColor(AppColor.secondaryText)
            Text(value)
                .appFont(size: 18, weight: .bold)
                .foregroundColor(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }

    private func featuredCard(title: String, detail: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .frame(width: 44, height: 44)

                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(tint)
            }

            Text(title)
                .appFont(size: 16, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            Text(detail)
                .appFont(size: 14, weight: .regular)
                .foregroundColor(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 168, maxHeight: 168, alignment: .topLeading)
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }
}

private struct ToolDestinationView: View {
    let tool: ToolItem

    var body: some View {
        switch tool.id {
        case "calculator":
            CalculatorView()
        case "unit-converter":
            UnitConverterView()
        case "qr-toolkit":
            QRCodeToolView()
        case "watermark":
            WatermarkView()
        case "compressor":
            ImageCompressorView()
        case "speech-to-text":
            VoiceToTextView()
        default:
            Text(tool.title)
        }
    }
}

private struct ToolTile: View {
    let tool: ToolItem

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tool.color.opacity(0.14))
                    .frame(width: 48, height: 48)

                Image(systemName: tool.symbol)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(tool.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(tool.title)
                    .appFont(size: 18, weight: .bold)
                    .foregroundColor(AppColor.primaryText)

                Text(tool.subtitle)
                    .appFont(size: 14, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
                    .lineLimit(2)

                Text(tool.description)
                    .appFont(size: 13, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 176, maxHeight: 176, alignment: .topLeading)
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }
}

private struct BadgeView: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .appFont(size: 13, weight: .bold)
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }
}

private struct RecentActivityCard: View {
    let title: String
    let value: String
    let color: Color
    let symbol: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.14))
                    .frame(width: 44, height: 44)

                Image(systemName: symbol)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .appFont(size: 15, weight: .bold)
                    .foregroundColor(AppColor.primaryText)
                Text(value)
                    .appFont(size: 14, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }
}
