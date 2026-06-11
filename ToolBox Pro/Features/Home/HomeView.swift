import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var purchaseStore: PurchaseStore
    @AppStorage("calculatorHistory") private var calculatorHistory = ""
    @AppStorage("voiceToTextHistory") private var voiceToTextHistory = ""
    @AppStorage("recentToolIDs") private var recentToolIDs = ""
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool

    private var tools: [ToolItem] { ToolItem.all }
    private var primaryTools: [ToolItem] { Array(tools.prefix(3)) }
    private var secondaryTools: [ToolItem] { Array(tools.dropFirst(3)) }
    private var popularTasks: [PopularTask] {
        [
            PopularTask(id: "scan-qr", toolID: "qr-toolkit", title: AppLocalizer.string("Scan QR"), detail: AppLocalizer.string("Open links, Wi-Fi, and contact codes"), symbol: "qrcode.viewfinder", color: AppColor.warning),
            PopularTask(id: "make-qr", toolID: "qr-toolkit", title: AppLocalizer.string("Make QR"), detail: AppLocalizer.string("Create codes for text, links, Wi-Fi, and phone"), symbol: "qrcode", color: AppColor.primary),
            PopularTask(id: "photo-pdf", toolID: "image-pdf", title: AppLocalizer.string("Photo to PDF"), detail: AppLocalizer.string("Export receipts, notes, and screenshots as PDF"), symbol: "doc.richtext", color: Color(hex: 0x2563EB)),
            PopularTask(id: "compress-image", toolID: "compressor", title: AppLocalizer.string("Compress Photos"), detail: AppLocalizer.string("Reduce image size before upload or sharing"), symbol: "arrow.down.right.and.arrow.up.left", color: Color(hex: 0x0EA5A8)),
            PopularTask(id: "watermark-photo", toolID: "watermark", title: AppLocalizer.string("Add Watermark"), detail: AppLocalizer.string("Protect ID photos, documents, and screenshots"), symbol: "seal.fill", color: Color(hex: 0x8B5CF6)),
            PopularTask(id: "voice-note", toolID: "speech-to-text", title: AppLocalizer.string("Voice Notes"), detail: AppLocalizer.string("Turn meetings and ideas into editable text"), symbol: "waveform", color: Color(hex: 0xF15B6C)),
            PopularTask(id: "discount-math", toolID: "calculator", title: AppLocalizer.string("Discount Math"), detail: AppLocalizer.string("Calculate totals, discounts, tips, and tax"), symbol: "percent", color: AppColor.success)
        ]
    }
    private var recentTools: [ToolItem] {
        RecentToolStorage.loadToolIDs(from: recentToolIDs)
            .compactMap { id in tools.first(where: { $0.id == id }) }
    }
    private var filteredTools: [ToolItem] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return tools }
        return tools.filter {
            [$0.title, $0.subtitle, $0.description, $0.searchKeywords.joined(separator: " ")]
                .joined(separator: " ")
                .localizedCaseInsensitiveContains(keyword)
        }
    }
    private var latestCalculation: TaggedHistoryRecord? { HistoryStorage.loadRecords(from: calculatorHistory).first }
    private var latestTranscript: TaggedHistoryRecord? { HistoryStorage.loadRecords(from: voiceToTextHistory).first }

    var body: some View {
        ZStack {
            HomeBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    editorialHeader
                    searchSection
                    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        popularTasksSection
                        spotlightSection
                        quickLaunchSection
                        recentToolsSection
                        primaryCollectionSection
                        utilityCollectionSection
                        recentActivitySection
                    } else {
                        searchResultsSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
            .simultaneousGesture(
                TapGesture().onEnded {
                    dismissSearchKeyboard()
                }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 8).onChanged { _ in
                    dismissSearchKeyboard()
                }
            )
        }
        .navigationTitle(AppLocalizer.string("Tools"))
        .navigationBarTitleDisplayMode(.inline)
        // In-app purchase entry is temporarily hidden.
        // .toolbar {
        //     ToolbarItem(placement: .navigationBarTrailing) {
        //         NavigationLink(destination: PaywallView().hidesTabBarOnPush()) {
        //             Text(purchaseStore.isProUnlocked ? AppLocalizer.string("Pro") : AppLocalizer.string("Go Pro"))
        //                 .appFont(size: 14, weight: .bold)
        //                 .foregroundColor(purchaseStore.isProUnlocked ? AppColor.success : AppColor.primary)
        //         }
        //         .feedbackOnTap()
        //     }
        // }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColor.secondaryText)

                TextField(AppLocalizer.string("Search tools"), text: $searchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($isSearchFieldFocused)

                if !searchText.isEmpty {
                    Button {
                        AppFeedback.selection()
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColor.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(AppColor.surface.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColor.border.opacity(0.75), lineWidth: 1)
            )

            Text(AppLocalizer.string("Find a tool by name or task."))
                .appFont(size: 13, weight: .medium)
                .foregroundColor(AppColor.secondaryText)
        }
    }

    private func dismissSearchKeyboard() {
        guard isSearchFieldFocused else { return }
        isSearchFieldFocused = false
    }

    private var editorialHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Text(AppLocalizer.string("One Tools"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColor.secondaryText)
                    .tracking(1.4)

                Circle()
                    .fill(AppColor.success.opacity(0.7))
                    .frame(width: 5, height: 5)

                // Purchase-status copy is temporarily hidden.
                Text(AppLocalizer.string("Daily utilities"))
                    .appFont(size: 12, weight: .medium)
                    .foregroundColor(AppColor.secondaryText)
            }

            Text(AppLocalizer.string("QR, image, voice, and calculator tools"))
                .appFont(size: 32, weight: .bold)
                .foregroundColor(AppColor.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(AppLocalizer.string("Scan codes, compress photos, add watermarks, convert units, and transcribe voice notes without jumping between apps."))
                .appFont(size: 16, weight: .medium)
                .foregroundColor(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var popularTasksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                eyebrow: AppLocalizer.string("Popular Tasks"),
                title: AppLocalizer.string("Start with what you need")
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(popularTasks) { task in
                        NavigationLink(destination: destination(for: task).hidesTabBarOnPush()) {
                            PopularTaskCard(task: task)
                        }
                        .buttonStyle(.plain)
                        .feedbackOnTap(.action)
                        .simultaneousGesture(TapGesture().onEnded {
                            recordRecentTool(task.toolID)
                        })
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private var spotlightSection: some View {
        NavigationLink(destination: QRCodeToolView(initialMode: .scan).hidesTabBarOnPush()) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.dynamic(light: 0x18212F, dark: 0x162033),
                                Color.dynamic(light: 0x21304A, dark: 0x1E2E49),
                                Color.dynamic(light: 0x172132, dark: 0x111827)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(AppColor.warning.opacity(0.18))
                    .frame(width: 180, height: 180)
                    .blur(radius: 4)
                    .offset(x: 160, y: -10)

                Circle()
                    .fill(AppColor.primary.opacity(0.20))
                    .frame(width: 220, height: 220)
                    .blur(radius: 4)
                    .offset(x: -30, y: 110)

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text(AppLocalizer.string("Featured"))
                            .appFont(size: 12, weight: .bold)
                            .foregroundColor(.white.opacity(0.72))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.10))
                            .clipShape(Capsule())

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.72))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppLocalizer.string("Scan QR codes"))
                            .appFont(size: 28, weight: .bold)
                            .foregroundColor(.white)

                        Text(AppLocalizer.string("Open the scanner for links, Wi-Fi, and quick sharing without extra steps."))
                            .appFont(size: 15, weight: .medium)
                            .foregroundColor(.white.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 10) {
                        HeroMetric(title: AppLocalizer.string("Use"), value: AppLocalizer.string("Fast access"))
                        HeroMetric(title: AppLocalizer.string("Tool"), value: AppLocalizer.string("Scanner"))
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        }
        .buttonStyle(.plain)
        .feedbackOnTap(.action)
        .simultaneousGesture(TapGesture().onEnded {
            recordRecentTool("qr-toolkit")
        })
    }

    private var quickLaunchSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                eyebrow: AppLocalizer.string("Quick Launch"),
                title: AppLocalizer.string("Most opened")
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    NavigationLink(destination: CalculatorView().hidesTabBarOnPush()) {
                        QuickLaunchCard(
                            eyebrow: AppLocalizer.string("Quick math"),
                            title: AppLocalizer.string("Calculator"),
                            detail: AppLocalizer.string("Totals, discounts, and quick math"),
                            symbol: "plus.forwardslash.minus",
                            tint: AppColor.primary
                        )
                    }
                    .buttonStyle(.plain)
                    .feedbackOnTap()
                    .simultaneousGesture(TapGesture().onEnded {
                        recordRecentTool("calculator")
                    })

                    NavigationLink(destination: UnitConverterView().hidesTabBarOnPush()) {
                        QuickLaunchCard(
                            eyebrow: AppLocalizer.string("Global units"),
                            title: AppLocalizer.string("Convert"),
                            detail: AppLocalizer.string("Length, weight, time, and more"),
                            symbol: "arrow.left.arrow.right",
                            tint: AppColor.success
                        )
                    }
                    .buttonStyle(.plain)
                    .feedbackOnTap()
                    .simultaneousGesture(TapGesture().onEnded {
                        recordRecentTool("unit-converter")
                    })

                    NavigationLink(destination: VoiceToTextView().hidesTabBarOnPush()) {
                        QuickLaunchCard(
                            eyebrow: AppLocalizer.string("Transcribe audio"),
                            title: AppLocalizer.string("Transcribe"),
                            detail: AppLocalizer.string("Turn speech into editable text"),
                            symbol: "waveform",
                            tint: Color(hex: 0xF15B6C)
                        )
                    }
                    .buttonStyle(.plain)
                    .feedbackOnTap()
                    .simultaneousGesture(TapGesture().onEnded {
                        recordRecentTool("speech-to-text")
                    })
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private var recentToolsSection: some View {
        Group {
            if !recentTools.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    sectionHeader(
                        eyebrow: AppLocalizer.string("Recent Tools"),
                        title: AppLocalizer.string("Open again quickly")
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(recentTools.prefix(4)) { tool in
                                NavigationLink(destination: ToolDestinationView(tool: tool).hidesTabBarOnPush()) {
                                    QuickLaunchCard(
                                        eyebrow: AppLocalizer.string("Recent"),
                                        title: tool.title,
                                        detail: tool.description,
                                        symbol: tool.symbol,
                                        tint: tool.color
                                    )
                                }
                                .buttonStyle(.plain)
                                .feedbackOnTap()
                                .simultaneousGesture(TapGesture().onEnded {
                                    recordRecentTool(tool.id)
                                })
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }
        }
    }

    private var primaryCollectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                eyebrow: AppLocalizer.string("Core Tools"),
                title: AppLocalizer.string("Main tools")
            )

            VStack(spacing: 12) {
                ForEach(primaryTools) { tool in
                    NavigationLink(destination: ToolDestinationView(tool: tool).hidesTabBarOnPush()) {
                        HomeListCard(tool: tool)
                    }
                    .buttonStyle(.plain)
                    .feedbackOnTap()
                    .simultaneousGesture(TapGesture().onEnded {
                        recordRecentTool(tool.id)
                    })
                }
            }
        }
    }

    private var utilityCollectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                eyebrow: AppLocalizer.string("Create & Export"),
                title: AppLocalizer.string("Save and share")
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(secondaryTools) { tool in
                    NavigationLink(destination: ToolDestinationView(tool: tool).hidesTabBarOnPush()) {
                        CompactToolCard(tool: tool)
                    }
                    .buttonStyle(.plain)
                    .feedbackOnTap()
                    .simultaneousGesture(TapGesture().onEnded {
                        recordRecentTool(tool.id)
                    })
                }
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                eyebrow: AppLocalizer.string("Recent Activity"),
                title: AppLocalizer.string("Recent items")
            )

            VStack(spacing: 10) {
                if let calc = latestCalculation, !calc.text.isEmpty {
                    RecentActivityCard(
                        title: AppLocalizer.string("Last Calculation"),
                        value: calc.text,
                        color: AppColor.primary,
                        symbol: "plus.forwardslash.minus"
                    )
                }

                if let transcript = latestTranscript, !transcript.text.isEmpty {
                    RecentActivityCard(
                        title: AppLocalizer.string("Last Transcript"),
                        value: transcript.text,
                        color: AppColor.success,
                        symbol: "waveform"
                    )
                }

                if latestCalculation == nil && latestTranscript == nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppLocalizer.string("No recent items"))
                            .appFont(size: 16, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        Text(AppLocalizer.string("Calculations and transcripts will show up here after you use the tools."))
                            .appFont(size: 14, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppColor.border.opacity(0.7), lineWidth: 1)
                    )
                }
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                eyebrow: AppLocalizer.string("Results"),
                title: AppLocalizer.string("Matching tools")
            )

            if filteredTools.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppLocalizer.string("No matching tools"))
                        .appFont(size: 16, weight: .bold)
                        .foregroundColor(AppColor.primaryText)

                    Text(AppLocalizer.string("Try another keyword like QR, image, voice, or calculator."))
                        .appFont(size: 14, weight: .regular)
                        .foregroundColor(AppColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(AppColor.surface.opacity(0.94))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppColor.border.opacity(0.75), lineWidth: 1)
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredTools) { tool in
                        NavigationLink(destination: ToolDestinationView(tool: tool).hidesTabBarOnPush()) {
                            HomeListCard(tool: tool)
                        }
                        .buttonStyle(.plain)
                        .feedbackOnTap()
                        .simultaneousGesture(TapGesture().onEnded {
                            recordRecentTool(tool.id)
                        })
                    }
                }
            }
        }
    }

    private func recordRecentTool(_ id: String) {
        recentToolIDs = RecentToolStorage.register(id, in: recentToolIDs)
    }

    @ViewBuilder
    private func destination(for task: PopularTask) -> some View {
        switch task.id {
        case "scan-qr":
            QRCodeToolView(initialMode: .scan)
        case "make-qr":
            QRCodeToolView(initialMode: .generate)
        case "photo-pdf":
            ImagePDFView()
        default:
            if let tool = tools.first(where: { $0.id == task.toolID }) {
                ToolDestinationView(tool: tool)
            } else {
                EmptyView()
            }
        }
    }

    private func sectionHeader(eyebrow: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow)
                .appFont(size: 12, weight: .bold)
                .foregroundColor(AppColor.secondaryText)

            Text(title)
                .appFont(size: 24, weight: .bold)
                .foregroundColor(AppColor.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
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
        case "image-pdf":
            ImagePDFView()
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

private struct HomeBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.dynamic(light: 0xF6F8FB, dark: 0x0B1220),
                    Color.dynamic(light: 0xF2F5F9, dark: 0x0F172A),
                    Color.dynamic(light: 0xEDF2F7, dark: 0x111827)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(hex: 0x8FB8FF, opacity: 0.14))
                .frame(width: 320, height: 320)
                .blur(radius: 24)
                .offset(x: -120, y: -340)

            Circle()
                .fill(Color(hex: 0x9EDAC2, opacity: 0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 22)
                .offset(x: 150, y: -120)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.20),
                            .white.opacity(0.03)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(-12))
                .blur(radius: 10)
                .offset(x: 210, y: 230)
        }
        .allowsHitTesting(false)
    }
}

private struct HeroMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .appFont(size: 11, weight: .medium)
                .foregroundColor(.white.opacity(0.60))

            Text(value)
                .appFont(size: 14, weight: .bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct PopularTask: Identifiable {
    let id: String
    let toolID: String
    let title: String
    let detail: String
    let symbol: String
    let color: Color
}

private struct PopularTaskCard: View {
    let task: PopularTask

    private let cardWidth: CGFloat = 176
    private let cardHeight: CGFloat = 154

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(task.color.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: task.symbol)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(task.color)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColor.secondaryText.opacity(0.65))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .appFont(size: 17, weight: .bold)
                    .foregroundColor(AppColor.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)

                Text(task.detail)
                    .appFont(size: 13, weight: .medium)
                    .foregroundColor(AppColor.secondaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .topLeading)
            }

            Spacer(minLength: 0)
        }
        .padding(15)
        .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
        .background(AppColor.surface.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColor.border.opacity(0.75), lineWidth: 1)
        )
    }
}

private struct QuickLaunchCard: View {
    let eyebrow: String
    let title: String
    let detail: String
    let symbol: String
    let tint: Color

    private let cardWidth: CGFloat = 214
    private let cardHeight: CGFloat = 196
    private let footerHeight: CGFloat = 56
    private var contentHeight: CGFloat { cardHeight - footerHeight }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Text(eyebrow.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(tint)
                        .tracking(0.6)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(tint.opacity(0.10))
                        .clipShape(Capsule())

                    Spacer(minLength: 8)

                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(tint.opacity(0.14))
                            .frame(width: 42, height: 42)

                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(tint)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .appFont(size: 18, weight: .bold)
                        .foregroundColor(AppColor.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(detail)
                        .appFont(size: 13, weight: .regular)
                        .foregroundColor(AppColor.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: contentHeight, maxHeight: contentHeight, alignment: .topLeading)

            HStack {
                Text(AppLocalizer.string("Open"))
                    .appFont(size: 12, weight: .bold)
                    .foregroundColor(tint)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(tint)
            }
            .frame(height: footerHeight)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint.opacity(0.08))
            )
            .padding(8)
        }
        .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    AppColor.surface.opacity(0.98),
                    tint.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(AppColor.surface.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppColor.border.opacity(0.75), lineWidth: 1)
        )
    }
}

private struct HomeListCard: View {
    let tool: ToolItem

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tool.color.opacity(0.12))
                    .frame(width: 58, height: 58)

                Image(systemName: tool.symbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(tool.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(tool.title)
                    .appFont(size: 18, weight: .bold)
                    .foregroundColor(AppColor.primaryText)

                Text(tool.description)
                    .appFont(size: 14, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(tool.subtitle)
                    .appFont(size: 12, weight: .bold)
                    .foregroundColor(tool.color)
                    .multilineTextAlignment(.trailing)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColor.secondaryText.opacity(0.65))
            }
        }
        .padding(18)
        .background(AppColor.surface.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppColor.border.opacity(0.75), lineWidth: 1)
        )
    }
}

private struct CompactToolCard: View {
    let tool: ToolItem

    private let cardHeight: CGFloat = 172

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tool.color.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: tool.symbol)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(tool.color)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColor.secondaryText.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(tool.title)
                    .appFont(size: 16, weight: .bold)
                    .foregroundColor(AppColor.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40, alignment: .topLeading)

                Text(tool.description)
                    .appFont(size: 13, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50, alignment: .topLeading)
            }

            Text(tool.subtitle)
                .appFont(size: 12, weight: .bold)
                .foregroundColor(tool.color)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tool.color.opacity(0.10))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight, alignment: .topLeading)
        .padding(16)
        .background(AppColor.surface.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppColor.border.opacity(0.75), lineWidth: 1)
        )
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
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.14))
                    .frame(width: 46, height: 46)

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
        .background(AppColor.surface.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColor.border.opacity(0.75), lineWidth: 1)
        )
    }
}
