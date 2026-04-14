import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var purchaseStore: PurchaseStore

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: AppColor.primary, secondaryTint: AppColor.warning)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    settingsHeader

                    VStack(alignment: .leading, spacing: 12) {
                        settingsSectionHeader(
                            eyebrow: AppLocalizer.string("Preferences"),
                            title: AppLocalizer.string("Make the app feel right for you")
                        )

                        NavigationLink(destination: AppearanceSettingsView().hidesTabBarOnPush()) {
                            SettingsRow(icon: "paintbrush", title: AppLocalizer.string("Appearance"), subtitle: AppLocalizer.string("Theme, contrast, and preview"))
                        }.buttonStyle(.plain)

                        NavigationLink(destination: PrivacySettingsView().hidesTabBarOnPush()) {
                            SettingsRow(icon: "lock.shield", title: AppLocalizer.string("Privacy"), subtitle: AppLocalizer.string("History controls and local data cleanup"))
                        }.buttonStyle(.plain)

                        NavigationLink(destination: LanguageSettingsView().hidesTabBarOnPush()) {
                            SettingsRow(icon: "globe", title: AppLocalizer.string("Language"), subtitle: AppLocalizer.string("Interface preference and voice defaults"))
                        }.buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        settingsSectionHeader(
                            eyebrow: AppLocalizer.string("Upgrade"),
                            title: AppLocalizer.string("Keep Pro ready across devices")
                        )

                        NavigationLink(destination: PaywallView().hidesTabBarOnPush()) {
                            SettingsRow(
                                icon: purchaseStore.isProUnlocked ? "checkmark.seal.fill" : "sparkles",
                                title: purchaseStore.isProUnlocked ? AppLocalizer.string("Pro Unlocked") : AppLocalizer.string("Go Pro"),
                                subtitle: purchaseStore.isProUnlocked ? AppLocalizer.string("Restorable on your devices with the same Apple ID") : AppLocalizer.string("Monthly subscription with restore support"),
                                accessoryColor: purchaseStore.isProUnlocked ? AppColor.success : AppColor.warning
                            )
                        }.buttonStyle(.plain)
                    }

                    settingsStatusCard
                }
                .padding(20)
            }
        }
        .navigationTitle(AppLocalizer.string("Settings"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(AppLocalizer.string("SETTINGS"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColor.secondaryText)
                .tracking(1.4)

            Text(AppLocalizer.string("Settings"))
                .appFont(size: 34, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            Text(AppLocalizer.string("Control appearance, privacy, language, and your Pro access from one place."))
                .appFont(size: 17, weight: .medium)
                .foregroundColor(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                settingsChip(
                    title: AppLocalizer.string("Plan"),
                    value: purchaseStore.isProUnlocked ? AppLocalizer.string("Pro Monthly") : AppLocalizer.string("Free"),
                    tint: purchaseStore.isProUnlocked ? AppColor.success : AppColor.primary
                )
                settingsChip(
                    title: AppLocalizer.string("Subscription"),
                    value: purchaseStore.subscriptionStatusTitle,
                    tint: purchaseStore.isProUnlocked ? AppColor.success : AppColor.warning
                )
            }
        }
    }

    private var settingsStatusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsSectionHeader(
                eyebrow: AppLocalizer.string("App Status"),
                title: AppLocalizer.string("Current build and access")
            )

            statusLine(title: AppLocalizer.string("Version"), value: Bundle.main.releaseVersionNumber)
            statusLine(title: AppLocalizer.string("Build"), value: Bundle.main.buildVersionNumber)
            statusLine(title: AppLocalizer.string("Subscription"), value: purchaseStore.subscriptionStatusTitle)

            Text(AppLocalizer.string("Core tools are ready offline for fast daily use."))
                .foregroundColor(AppColor.secondaryText)
                .appFont(size: 14, weight: .regular)
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }

    private func settingsChip(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .appFont(size: 12, weight: .medium)
                .foregroundColor(AppColor.secondaryText)
            Text(value)
                .appFont(size: 18, weight: .bold)
                .foregroundColor(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func settingsSectionHeader(eyebrow: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow)
                .appFont(size: 13, weight: .bold)
                .foregroundColor(AppColor.secondaryText)

            Text(title)
                .appFont(size: 24, weight: .bold)
                .foregroundColor(AppColor.primaryText)
        }
    }

    private func statusLine(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .appFont(size: 14, weight: .medium)
                .foregroundColor(AppColor.secondaryText)
            Spacer()
            Text(value)
                .appFont(size: 14, weight: .bold)
                .foregroundColor(AppColor.primaryText)
        }
        .padding(.vertical, 2)
    }

    private var currentLanguageTitle: String {
        let rawValue = UserDefaults.standard.string(forKey: "preferredInterfaceLanguage") ?? InterfaceLanguage.english.rawValue
        return InterfaceLanguage(rawValue: rawValue)?.title ?? "English"
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("appAppearance") private var selectedAppearanceRawValue = AppAppearance.system.rawValue

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: selectedAppearanceRawValue) ?? .system
    }

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: AppColor.primary, secondaryTint: AppColor.success)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppLocalizer.string("Theme"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        Picker(AppLocalizer.string("Appearance"), selection: $selectedAppearanceRawValue) {
                            ForEach(AppAppearance.allCases) { appearance in
                                Text(appearance.title).tag(appearance.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(appearanceSubtitle)
                            .appFont(size: 14, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)
                    }
                    .padding(16)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppLocalizer.string("Preview"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        HStack(spacing: 14) {
                            appearancePreviewCard(title: AppLocalizer.string("Primary"), color: AppColor.primary)
                            appearancePreviewCard(title: AppLocalizer.string("Success"), color: AppColor.success)
                        }
                    }
                    .padding(16)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(20)
            }
        }
        .navigationTitle(AppLocalizer.string("Appearance"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appearanceSubtitle: String {
        switch selectedAppearance {
        case .system:
            return AppLocalizer.string("Matches the device appearance automatically.")
        case .light:
            return AppLocalizer.string("Keeps the app bright for daytime use.")
        case .dark:
            return AppLocalizer.string("Reduces glare in low-light environments.")
        }
    }

    private func appearancePreviewCard(title: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color)
                .frame(height: 72)

            Text(title)
                .appFont(size: 16, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            Text(selectedAppearance.title)
                .appFont(size: 14, weight: .regular)
                .foregroundColor(AppColor.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }
}

struct PrivacySettingsView: View {
    @AppStorage("saveCalculatorHistoryEnabled") private var saveCalculatorHistoryEnabled = true
    @AppStorage("saveTranscriptHistoryEnabled") private var saveTranscriptHistoryEnabled = true
    @AppStorage("calculatorHistory") private var calculatorHistory = ""
    @AppStorage("voiceToTextHistory") private var voiceToTextHistory = ""

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: AppColor.success, secondaryTint: AppColor.primary)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(AppLocalizer.string("History Controls"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        Toggle(AppLocalizer.string("Save calculator history"), isOn: $saveCalculatorHistoryEnabled)
                            .tint(AppColor.primary)
                        Toggle(AppLocalizer.string("Save voice transcripts"), isOn: $saveTranscriptHistoryEnabled)
                            .tint(AppColor.primary)
                    }
                    .padding(16)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 14) {
                        Text(AppLocalizer.string("Local Data"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        Text(AppLocalizer.string("Tool history is stored only on this device and can be cleared at any time."))
                            .appFont(size: 14, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)

                        Button(AppLocalizer.string("Clear calculator history")) { calculatorHistory = "" }
                            .buttonStyle(SettingsActionButtonStyle(color: AppColor.primary))
                        Button(AppLocalizer.string("Clear transcript history")) { voiceToTextHistory = "" }
                            .buttonStyle(SettingsActionButtonStyle(color: AppColor.warning))
                    }
                    .padding(16)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 14) {
                        Text(AppLocalizer.string("Permission Notes"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        PermissionNoteRow(title: AppLocalizer.string("Camera"), detail: AppLocalizer.string("Used only for QR code scanning."))
                        PermissionNoteRow(title: AppLocalizer.string("Microphone"), detail: AppLocalizer.string("Used only when you start Voice to Text recording."))
                        PermissionNoteRow(title: AppLocalizer.string("Speech Recognition"), detail: AppLocalizer.string("Used only to create live transcripts."))
                        PermissionNoteRow(title: AppLocalizer.string("Photo Library"), detail: AppLocalizer.string("Used only to save QR codes and edited images. Image picking uses the system picker."))
                    }
                    .padding(16)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(20)
            }
        }
        .navigationTitle(AppLocalizer.string("Privacy"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: saveCalculatorHistoryEnabled) { enabled in
            if !enabled {
                calculatorHistory = ""
            }
        }
        .onChange(of: saveTranscriptHistoryEnabled) { enabled in
            if !enabled {
                voiceToTextHistory = ""
            }
        }
    }
}

struct LanguageSettingsView: View {
    @AppStorage("preferredInterfaceLanguage") private var preferredInterfaceLanguage = InterfaceLanguage.english.rawValue
    @AppStorage("defaultVoiceLanguage") private var defaultVoiceLanguage = VoiceLanguage.english.rawValue

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: AppColor.primary, secondaryTint: AppColor.warning)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppLocalizer.string("Interface Language"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        Menu {
                            ForEach(InterfaceLanguage.allCases) { language in
                                Button(language.title) { preferredInterfaceLanguage = language.rawValue }
                            }
                        } label: {
                            SettingsSelectionRow(icon: "character.book.closed", title: selectedInterfaceLanguage.title, subtitle: interfaceLanguageSubtitle)
                        }

                        Text(AppLocalizer.string("Sets the preferred interface locale for the app."))
                            .appFont(size: 14, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)
                    }
                    .padding(16)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppLocalizer.string("Voice to Text Default"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        Menu {
                            ForEach(VoiceLanguage.allCases) { language in
                                Button(language.title) { defaultVoiceLanguage = language.rawValue }
                            }
                        } label: {
                            SettingsSelectionRow(icon: "waveform.badge.mic", title: selectedVoiceLanguage.title, subtitle: AppLocalizer.string("Used as the default language when you open Voice to Text."))
                        }
                    }
                    .padding(16)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(20)
            }
        }
        .navigationTitle(AppLocalizer.string("Language"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var selectedInterfaceLanguage: InterfaceLanguage {
        InterfaceLanguage(rawValue: preferredInterfaceLanguage) ?? .english
    }

    private var selectedVoiceLanguage: VoiceLanguage {
        VoiceLanguage(rawValue: defaultVoiceLanguage) ?? .english
    }

    private var interfaceLanguageSubtitle: String {
        switch selectedInterfaceLanguage {
        case .english:
            return AppLocalizer.string("Best for global defaults and app store copy.")
        case .spanish:
            return AppLocalizer.string("Useful for Spain and Latin America audiences.")
        case .french:
            return AppLocalizer.string("Common for Europe and Canada.")
        case .german:
            return AppLocalizer.string("Popular for DACH region users.")
        case .portugueseBrazil:
            return AppLocalizer.string("Strong fit for Brazil and Portuguese speakers.")
        case .japanese:
            return AppLocalizer.string("Good for Japan launch preparation.")
        case .chineseSimplified:
            return AppLocalizer.string("Helpful for Mainland Chinese readers.")
        case .korean:
            return AppLocalizer.string("Useful for South Korea audiences.")
        }
    }
}

struct PaywallView: View {
    @EnvironmentObject private var purchaseStore: PurchaseStore

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: AppColor.primary, secondaryTint: AppColor.success)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    paywallHero

                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppLocalizer.string("Plan"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .lastTextBaseline, spacing: 8) {
                                    Text(purchaseStore.product?.displayPrice ?? "$4.99")
                                        .appFont(size: 34, weight: .bold)
                                        .foregroundColor(AppColor.primaryText)
                                    Text(AppLocalizer.string("Monthly"))
                                        .appFont(size: 16, weight: .medium)
                                        .foregroundColor(AppColor.secondaryText)
                                }

                                Text(AppLocalizer.string("Auto-renews monthly. Cancel anytime in App Store settings."))
                                    .appFont(size: 14, weight: .regular)
                                    .foregroundColor(AppColor.secondaryText)
                            }

                            Spacer()

                            Text(purchaseStore.isProUnlocked ? AppLocalizer.string("Active") : AppLocalizer.string("Best Value"))
                                .appFont(size: 12, weight: .bold)
                                .foregroundColor(purchaseStore.isProUnlocked ? AppColor.success : AppColor.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background((purchaseStore.isProUnlocked ? AppColor.success : AppColor.primary).opacity(0.14))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(16)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppColor.border, lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        Text(AppLocalizer.string("What you get"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        planFeatureRow(symbol: "checkmark.circle.fill", text: AppLocalizer.string("Keeps the full tool set ready offline"))
                        planFeatureRow(symbol: "checkmark.circle.fill", text: AppLocalizer.string("Use Pro while your subscription is active"))
                        planFeatureRow(symbol: "checkmark.circle.fill", text: AppLocalizer.string("Restore anytime with the same Apple ID while active"))
                        planFeatureRow(symbol: "checkmark.circle.fill", text: AppLocalizer.string("If the subscription expires and does not renew, Pro access ends automatically"))
                    }
                    .padding(16)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppColor.border, lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            benefitCard(title: AppLocalizer.string("Cleaner"), detail: AppLocalizer.string("Keep every core tool unlocked in one calm workspace."), tint: AppColor.primary)
                            benefitCard(title: AppLocalizer.string("Restorable"), detail: AppLocalizer.string("Sign in with the same Apple ID to restore your active subscription on a new device."), tint: AppColor.success)
                        }

                        Text(AppLocalizer.string("No extra account is needed. We check App Store subscription status each time the app starts."))
                            .appFont(size: 14, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)
                    }
                    .padding(16)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppColor.border, lineWidth: 1)
                    )

                    VStack(spacing: 12) {
                        Button(AppLocalizer.string("Unlock Pro")) {
                            Task { await purchaseStore.buy() }
                        }
                        .appFont(size: 16, weight: .bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColor.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Button(AppLocalizer.string("Restore Purchases")) {
                            Task { await purchaseStore.restorePurchases() }
                        }
                        .buttonStyle(SettingsActionButtonStyle(color: AppColor.primary))

                        Text(AppLocalizer.string("Already subscribed before? Restore takes a moment and syncs your active subscription on the same Apple ID."))
                            .appFont(size: 13, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    if !purchaseStore.statusMessage.isEmpty {
                        Text(purchaseStore.statusMessage)
                            .foregroundColor(AppColor.secondaryText)
                            .appFont(size: 14, weight: .medium)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    Spacer(minLength: 10)
                }
                .padding(20)
            }
        }
        .navigationTitle(AppLocalizer.string("OneTools Pro"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var paywallHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(purchaseStore.isProUnlocked ? AppLocalizer.string("Pro Is Active") : AppLocalizer.string("Go Pro"))
                        .appFont(size: 24, weight: .bold)
                        .foregroundColor(.white)

                    Text(AppLocalizer.string("Keep OneTools focused, fast, and ready across your devices."))
                        .appFont(size: 15, weight: .regular)
                        .foregroundColor(.white.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.16))
                        .frame(width: 54, height: 54)
                    Image(systemName: purchaseStore.isProUnlocked ? "checkmark.seal.fill" : "sparkles")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            HStack(spacing: 12) {
                heroMetric(title: AppLocalizer.string("Access"), value: AppLocalizer.string("Monthly"))
                heroMetric(title: AppLocalizer.string("Restore"), value: AppLocalizer.string("Included"))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x165DFF), Color(hex: 0x36D399)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func heroMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .appFont(size: 12, weight: .medium)
                .foregroundColor(.white.opacity(0.72))
            Text(value)
                .appFont(size: 16, weight: .bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func benefitCard(title: String, detail: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tint.opacity(0.14))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: "checkmark")
                        .foregroundColor(tint)
                )

            Text(title)
                .appFont(size: 15, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            Text(detail)
                .appFont(size: 13, weight: .regular)
                .foregroundColor(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }

    private func planFeatureRow(symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .foregroundColor(AppColor.success)
            Text(text)
                .appFont(size: 15, weight: .medium)
                .foregroundColor(AppColor.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SettingsActionButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appFont(size: 16, weight: .bold)
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColor.background)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(color.opacity(configuration.isPressed ? 0.4 : 1), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct PermissionNoteRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .appFont(size: 15, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            Text(detail)
                .appFont(size: 14, weight: .regular)
                .foregroundColor(AppColor.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var accessoryColor: Color = AppColor.primary

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(accessoryColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(accessoryColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .appFont(size: 16, weight: .bold)
                    .foregroundColor(AppColor.primaryText)
                Text(subtitle)
                    .appFont(size: 14, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppColor.secondaryText.opacity(0.6))
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border.opacity(0.7), lineWidth: 1)
        )
    }
}

private struct SettingsSelectionRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppColor.primary.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppColor.primary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .appFont(size: 16, weight: .bold)
                    .foregroundColor(AppColor.primaryText)
                Text(subtitle)
                    .appFont(size: 14, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppColor.secondaryText.opacity(0.7))
        }
        .padding(14)
        .background(AppColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border.opacity(0.7), lineWidth: 1)
        )
    }
}

extension Bundle {
    var releaseVersionNumber: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildVersionNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
