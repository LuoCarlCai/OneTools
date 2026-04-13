import SwiftUI

struct ContentView: View {
    @State private var showSplash = !ProcessInfo.processInfo.isRunningForPreviews
    @AppStorage("appAppearance") private var appAppearanceRawValue = AppAppearance.system.rawValue
    @AppStorage("preferredInterfaceLanguage") private var preferredInterfaceLanguage = InterfaceLanguage.english.rawValue

    var body: some View {
        ZStack {
            MainTabView(languageIdentifier: preferredInterfaceLanguage)
                .id(preferredInterfaceLanguage)

            if showSplash {
                AppSplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .preferredColorScheme(AppAppearance(rawValue: appAppearanceRawValue)?.colorScheme)
        .environment(\.locale, Locale(identifier: preferredInterfaceLanguage))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showSplash = false
                }
            }
        }
    }
}

extension ProcessInfo {
    var isRunningForPreviews: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

struct MainTabView: View {
    let languageIdentifier: String

    var body: some View {
        TabView {
            tabContainer { HomeView() }
                .tabItem { Label(AppLocalizer.string("Tools"), systemImage: "square.grid.2x2") }

            tabContainer { SettingsView() }
                .tabItem { Label(AppLocalizer.string("Settings"), systemImage: "gearshape") }
        }
        .accentColor(AppColor.primary)
    }

    @ViewBuilder
    private func tabContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
                .navigationViewStyle(.stack)
        }
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var title: String {
        switch self {
        case .system: return AppLocalizer.string("System")
        case .light: return AppLocalizer.string("Light")
        case .dark: return AppLocalizer.string("Dark")
        }
    }
}

enum InterfaceLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case portugueseBrazil = "pt-BR"
    case japanese = "ja"
    case chineseSimplified = "zh-Hans"
    case korean = "ko"

    var id: String { rawValue }
    var title: String {
        switch self {
        case .english: return AppLocalizer.string("English")
        case .spanish: return AppLocalizer.string("Spanish")
        case .french: return AppLocalizer.string("French")
        case .german: return AppLocalizer.string("German")
        case .portugueseBrazil: return AppLocalizer.string("Portuguese (BR)")
        case .japanese: return AppLocalizer.string("Japanese")
        case .chineseSimplified: return AppLocalizer.string("Chinese (Simplified)")
        case .korean: return AppLocalizer.string("Korean")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PurchaseStore(loadStoreKit: false))
    }
}
