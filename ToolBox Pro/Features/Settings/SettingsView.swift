import SwiftUI

struct SettingsView: View {
    @AppStorage("appAppearance") private var appAppearanceRawValue = AppAppearance.system.rawValue
    @Environment(\.openURL) private var openURL

    private let recommendedApps: [RecommendedApp] = [
        RecommendedApp(
            title: "Local Lock Vault",
            subtitle: "Private vault for sensitive files",
            description: "Lock photos, videos, notes, and documents in a local-first vault with a clean private access flow.",
            symbol: "lock.doc.fill",
            accentColor: AppColor.primary,
            appStoreURL: URL(string: "https://apps.apple.com/us/app/local-lock-vault/id6769601748"),
            searchTerm: "Local Lock Vault"
        ),
        RecommendedApp(
            title: "LocalHabit All",
            subtitle: "Habits, focus, journal, and tasks",
            description: "Keep routines, focus sessions, journal entries, and daily tasks together in one privacy-first workspace.",
            symbol: "checklist.checked",
            accentColor: AppColor.success,
            appStoreURL: URL(string: "https://apps.apple.com/us/app/localhabit-all/id6764466369"),
            searchTerm: "LocalHabit All"
        ),
        RecommendedApp(
            title: "LocalNote Secret",
            subtitle: "Private notes that stay on-device",
            description: "Capture personal notes and sensitive ideas in a simple local notebook designed for privacy and quick access.",
            symbol: "note.text.badge.shield.fill",
            accentColor: AppColor.warning,
            appStoreURL: URL(string: "https://apps.apple.com/us/app/localnote-secret/id6768145229"),
            searchTerm: "LocalNote Secret"
        )
    ]

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: AppColor.primary, secondaryTint: AppColor.warning)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    settingsHeader
                    settingsOverviewCard

                    VStack(alignment: .leading, spacing: 12) {
                        settingsSectionHeader(
                            eyebrow: AppLocalizer.string("Preferences"),
                            title: AppLocalizer.string("Make the app feel right for you")
                        )

                        VStack(spacing: 10) {
                            NavigationLink(destination: AppearanceSettingsView().hidesTabBarOnPush()) {
                                SettingsRow(icon: "paintbrush", title: AppLocalizer.string("Appearance"), subtitle: AppLocalizer.string("Theme, contrast, and preview"), accessoryColor: AppColor.primary)
                            }.buttonStyle(.plain)
                                .feedbackOnTap()

                            NavigationLink(destination: PrivacySettingsView().hidesTabBarOnPush()) {
                                SettingsRow(icon: "lock.shield", title: AppLocalizer.string("Privacy"), subtitle: AppLocalizer.string("History controls and local data cleanup"), accessoryColor: AppColor.success)
                            }.buttonStyle(.plain)
                                .feedbackOnTap()

                            NavigationLink(destination: LanguageSettingsView().hidesTabBarOnPush()) {
                                SettingsRow(icon: "globe", title: AppLocalizer.string("Language"), subtitle: AppLocalizer.string("Interface preference and voice defaults"), accessoryColor: AppColor.warning)
                            }.buttonStyle(.plain)
                                .feedbackOnTap()

                            NavigationLink(destination: FeedbackSettingsView().hidesTabBarOnPush()) {
                                SettingsRow(icon: "waveform.path", title: AppLocalizer.string("Feedback"), subtitle: AppLocalizer.string("Haptics and tap sounds"), accessoryColor: Color(hex: 0xF15B6C))
                            }.buttonStyle(.plain)
                                .feedbackOnTap()
                        }
                        .padding(12)
                        .background(AppColor.surface.opacity(0.94))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(AppColor.border.opacity(0.75), lineWidth: 1)
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        settingsSectionHeader(
                            eyebrow: AppLocalizer.string("More Apps"),
                            title: AppLocalizer.string("Explore our other apps")
                        )

                        Text(AppLocalizer.string("Privacy-first tools for habits, private notes, and secure storage."))
                            .appFont(size: 14, weight: .medium)
                            .foregroundColor(AppColor.secondaryText)

                        VStack(spacing: 12) {
                            ForEach(recommendedApps) { app in
                                recommendedAppCard(app)
                            }
                        }
                    }

                    // In-app purchase settings entry is temporarily hidden.
                    // VStack(alignment: .leading, spacing: 12) {
                    //     settingsSectionHeader(
                    //         eyebrow: AppLocalizer.string("Upgrade"),
                    //         title: AppLocalizer.string("Keep Pro ready across devices")
                    //     )
                    //
                    //     NavigationLink(destination: PaywallView().hidesTabBarOnPush()) {
                    //         SettingsRow(
                    //             icon: purchaseStore.isProUnlocked ? "checkmark.seal.fill" : "sparkles",
                    //             title: purchaseStore.isProUnlocked ? AppLocalizer.string("Pro Unlocked") : AppLocalizer.string("Go Pro"),
                    //             subtitle: purchaseStore.isProUnlocked ? AppLocalizer.string("Restorable on your devices with the same Apple ID") : AppLocalizer.string("Flexible subscription plans with restore support"),
                    //             accessoryColor: purchaseStore.isProUnlocked ? AppColor.success : AppColor.warning
                    //         )
                    //     }.buttonStyle(.plain)
                    //         .feedbackOnTap(.action)
                    // }

                }
                .padding(20)
            }
        }
        .navigationTitle(AppLocalizer.string("Settings"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Text(AppLocalizer.string("SETTINGS"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColor.secondaryText)
                    .tracking(1.4)

                Circle()
                    .fill(AppColor.primary.opacity(0.7))
                    .frame(width: 5, height: 5)

                Text(AppLocalizer.string("App Status"))
                    .appFont(size: 12, weight: .medium)
                    .foregroundColor(AppColor.secondaryText)
            }

            Text(AppLocalizer.string("Settings"))
                .appFont(size: 34, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            Text(AppLocalizer.string("Control appearance, privacy, language, and feedback from one place."))
                .appFont(size: 17, weight: .medium)
                .foregroundColor(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var settingsOverviewCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppLocalizer.string("Current build"))
                        .appFont(size: 24, weight: .bold)
                        .foregroundColor(AppColor.primaryText)

                    Text(AppLocalizer.string("Core tools are ready offline for fast daily use."))
                        .foregroundColor(AppColor.secondaryText)
                        .appFont(size: 14, weight: .regular)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 16)

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppColor.primary.opacity(0.10))
                        .frame(width: 54, height: 54)

                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppColor.primary)
                }
            }

            HStack(spacing: 10) {
                overviewBadge(title: AppLocalizer.string("Version"), value: Bundle.main.releaseVersionNumber, tint: AppColor.primary)
                overviewBadge(title: AppLocalizer.string("Build"), value: Bundle.main.buildVersionNumber, tint: AppColor.success)
            }

            HStack(spacing: 10) {
                overviewBadge(title: AppLocalizer.string("Appearance"), value: selectedAppearance.title, tint: AppColor.warning)
                overviewBadge(title: AppLocalizer.string("Language"), value: currentLanguageTitle, tint: Color(hex: 0xF15B6C))
            }
        }
        .padding(20)
        .background(AppColor.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColor.border.opacity(0.75), lineWidth: 1)
        )
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

    private var currentLanguageTitle: String {
        let rawValue = UserDefaults.standard.string(forKey: "preferredInterfaceLanguage") ?? InterfaceLanguage.defaultInterfaceLanguage.rawValue
        return InterfaceLanguage(rawValue: rawValue)?.title ?? InterfaceLanguage.english.title
    }

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRawValue) ?? .system
    }

    private func overviewBadge(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .appFont(size: 12, weight: .bold)
                .foregroundColor(AppColor.secondaryText)

            Text(value)
                .appFont(size: 15, weight: .bold)
                .foregroundColor(AppColor.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func recommendedAppCard(_ app: RecommendedApp) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(app.accentColor.opacity(0.12))
                        .frame(width: 54, height: 54)

                    Image(systemName: app.symbol)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(app.accentColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(app.title)
                        .appFont(size: 19, weight: .bold)
                        .foregroundColor(AppColor.primaryText)

                    Text(app.subtitle)
                        .appFont(size: 13, weight: .bold)
                        .foregroundColor(app.accentColor)

                    Text(app.description)
                        .appFont(size: 14, weight: .medium)
                        .foregroundColor(AppColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Button {
                guard let url = app.destinationURL else { return }
                openURL(url)
            } label: {
                HStack(spacing: 8) {
                    Text(AppLocalizer.string("Download"))
                        .appFont(size: 15, weight: .bold)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(app.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .feedbackOnTap(.action)
        }
        .padding(18)
        .background(AppColor.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppColor.border.opacity(0.75), lineWidth: 1)
        )
    }
}

private struct RecommendedApp: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let symbol: String
    let accentColor: Color
    let appStoreURL: URL?
    let searchTerm: String

    var destinationURL: URL? {
        appStoreURL ?? appStoreSearchURL
    }

    var appStoreSearchURL: URL? {
        var components = URLComponents(string: "https://apps.apple.com/us/search")
        components?.queryItems = [
            URLQueryItem(name: "term", value: searchTerm)
        ]
        return components?.url
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
                    settingsIntroCard(
                        icon: "paintbrush.pointed.fill",
                        tint: AppColor.primary,
                        title: AppLocalizer.string("Appearance"),
                        message: AppLocalizer.string("Theme, contrast, and preview")
                    )

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
                    .settingsSubpageCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppLocalizer.string("Preview"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        HStack(spacing: 14) {
                            appearancePreviewCard(title: AppLocalizer.string("Primary"), color: AppColor.primary)
                            appearancePreviewCard(title: AppLocalizer.string("Success"), color: AppColor.success)
                        }
                    }
                    .settingsSubpageCard()
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColor.border.opacity(0.8), lineWidth: 1)
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
                    settingsIntroCard(
                        icon: "lock.shield.fill",
                        tint: AppColor.success,
                        title: AppLocalizer.string("Privacy"),
                        message: AppLocalizer.string("History controls and local data cleanup")
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        Text(AppLocalizer.string("History Controls"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        Toggle(AppLocalizer.string("Save calculator history"), isOn: $saveCalculatorHistoryEnabled)
                            .tint(AppColor.primary)
                        Toggle(AppLocalizer.string("Save voice transcripts"), isOn: $saveTranscriptHistoryEnabled)
                            .tint(AppColor.primary)
                    }
                    .settingsSubpageCard()

                    VStack(alignment: .leading, spacing: 14) {
                        Text(AppLocalizer.string("Local Data"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        Text(AppLocalizer.string("Tool history is stored only on this device and can be cleared at any time."))
                            .appFont(size: 14, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)

                        Button(AppLocalizer.string("Clear calculator history")) {
                            AppFeedback.selection()
                            calculatorHistory = ""
                        }
                            .buttonStyle(SettingsActionButtonStyle(color: AppColor.primary))
                            .disabled(calculatorHistory.isEmpty)
                        Button(AppLocalizer.string("Clear transcript history")) {
                            AppFeedback.selection()
                            voiceToTextHistory = ""
                        }
                            .buttonStyle(SettingsActionButtonStyle(color: AppColor.warning))
                            .disabled(voiceToTextHistory.isEmpty)
                    }
                    .settingsSubpageCard()

                    VStack(alignment: .leading, spacing: 14) {
                        Text(AppLocalizer.string("Permission Notes"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        PermissionNoteRow(title: AppLocalizer.string("Camera"), detail: AppLocalizer.string("Used only for QR code scanning."))
                        PermissionNoteRow(title: AppLocalizer.string("Microphone"), detail: AppLocalizer.string("Used only when you start Voice to Text recording."))
                        PermissionNoteRow(title: AppLocalizer.string("Speech Recognition"), detail: AppLocalizer.string("Used only to create live transcripts."))
                        PermissionNoteRow(title: AppLocalizer.string("Photo Library"), detail: AppLocalizer.string("Used only to save QR codes and edited images. Image picking uses the system picker."))
                    }
                    .settingsSubpageCard()
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
    @AppStorage("preferredInterfaceLanguage") private var preferredInterfaceLanguage = InterfaceLanguage.defaultInterfaceLanguage.rawValue
    @AppStorage("defaultVoiceLanguage") private var defaultVoiceLanguage = VoiceLanguage.english.rawValue

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: AppColor.primary, secondaryTint: AppColor.warning)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    settingsIntroCard(
                        icon: "globe",
                        tint: AppColor.warning,
                        title: AppLocalizer.string("Language"),
                        message: AppLocalizer.string("Interface preference and voice defaults")
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppLocalizer.string("Interface Language"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        Menu {
                            ForEach(InterfaceLanguage.allCases) { language in
                                Button(language.title) {
                                    AppFeedback.selection()
                                    preferredInterfaceLanguage = language.rawValue
                                }
                            }
                        } label: {
                            SettingsSelectionRow(icon: "character.book.closed", title: selectedInterfaceLanguage.title, subtitle: interfaceLanguageSubtitle)
                        }

                        Text(AppLocalizer.string("Sets the preferred interface locale for the app."))
                            .appFont(size: 14, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)
                    }
                    .settingsSubpageCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppLocalizer.string("Voice to Text Default"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        Menu {
                            ForEach(VoiceLanguage.allCases) { language in
                                Button(language.title) {
                                    AppFeedback.selection()
                                    defaultVoiceLanguage = language.rawValue
                                }
                            }
                        } label: {
                            SettingsSelectionRow(icon: "waveform.badge.mic", title: selectedVoiceLanguage.title, subtitle: AppLocalizer.string("Used as the default language when you open Voice to Text."))
                        }
                    }
                    .settingsSubpageCard()
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

struct FeedbackSettingsView: View {
    @AppStorage("feedbackHapticsEnabled") private var hapticsEnabled = true
    @AppStorage("feedbackSoundStyle") private var feedbackSoundStyle = AppFeedbackSound.click.rawValue

    private var selectedSound: AppFeedbackSound {
        AppFeedbackSound(rawValue: feedbackSoundStyle) ?? .click
    }

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: AppColor.warning, secondaryTint: AppColor.primary)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    settingsIntroCard(
                        icon: "waveform.path",
                        tint: AppColor.warning,
                        title: AppLocalizer.string("Feedback"),
                        message: AppLocalizer.string("Haptics and tap sounds")
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        Text(AppLocalizer.string("Touch Feedback"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        Toggle(AppLocalizer.string("Haptic Feedback"), isOn: $hapticsEnabled)
                            .tint(AppColor.primary)
                            .onChange(of: hapticsEnabled) { enabled in
                                AppFeedback.hapticsEnabled = enabled
                                if enabled {
                                    AppFeedback.previewHaptic(style: .light)
                                }
                            }

                        Text(AppLocalizer.string("Adds a light tap response to key actions across the app."))
                            .appFont(size: 14, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)
                    }
                    .settingsSubpageCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppLocalizer.string("Tap Sound"))
                            .appFont(size: 18, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        Menu {
                            ForEach(AppFeedbackSound.allCases) { sound in
                                Button(sound.title) {
                                    feedbackSoundStyle = sound.rawValue
                                    AppFeedback.soundStyle = sound
                                    AppFeedback.previewSound()
                                }
                            }
                        } label: {
                            SettingsSelectionRow(
                                icon: "speaker.wave.2.fill",
                                title: selectedSound.title,
                                subtitle: AppLocalizer.string("Choose the sound style for taps and actions.")
                            )
                        }

                        HStack(spacing: 12) {
                            Button(AppLocalizer.string("Preview Haptic")) {
                                AppFeedback.previewHaptic()
                            }
                            .buttonStyle(SettingsActionButtonStyle(color: AppColor.primary))

                            Button(AppLocalizer.string("Preview Sound")) {
                                AppFeedback.previewSound()
                            }
                            .buttonStyle(SettingsActionButtonStyle(color: AppColor.warning))
                        }
                    }
                    .settingsSubpageCard()
                }
                .padding(20)
            }
        }
        .navigationTitle(AppLocalizer.string("Feedback"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AppFeedback.hapticsEnabled = hapticsEnabled
            AppFeedback.soundStyle = selectedSound
        }
    }
}

struct PaywallView: View {
    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: AppColor.primary, secondaryTint: AppColor.success)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(AppLocalizer.string("Feature Information"))
                            .appFont(size: 24, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        Text(AppLocalizer.string("Purchase-related content is temporarily hidden in this build."))
                            .appFont(size: 15, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(AppLocalizer.string("If this page is opened during testing, there is currently no in-app purchase action available here."))
                            .appFont(size: 14, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppColor.border, lineWidth: 1)
                    )
                }
                .padding(20)
                .padding(.bottom, 25)
            }
        }
        .navigationTitle(AppLocalizer.string("Feature Info"))
        .navigationBarTitleDisplayMode(.inline)
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
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accessoryColor.opacity(0.1))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(accessoryColor)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .appFont(size: 16, weight: .bold)
                    .foregroundColor(AppColor.primaryText)
                Text(subtitle)
                    .appFont(size: 14, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(accessoryColor.opacity(0.10))
                    .frame(width: 30, height: 30)

                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(accessoryColor)
            }
        }
        .padding(16)
        .background(AppColor.background.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
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
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColor.primary.opacity(0.1))
                    .frame(width: 44, height: 44)

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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColor.border.opacity(0.7), lineWidth: 1)
        )
    }
}

private func settingsIntroCard(icon: String, tint: Color, title: String, message: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.12))
                .frame(width: 56, height: 56)

            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(tint)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .appFont(size: 24, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            Text(message)
                .appFont(size: 14, weight: .regular)
                .foregroundColor(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: 0)
    }
    .padding(20)
    .background(AppColor.surface.opacity(0.96))
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    .overlay(
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(AppColor.border.opacity(0.75), lineWidth: 1)
    )
}

private extension View {
    func settingsSubpageCard() -> some View {
        padding(18)
            .background(AppColor.surface.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppColor.border.opacity(0.75), lineWidth: 1)
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
