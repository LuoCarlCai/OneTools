import SwiftUI

@main
struct ToolBox_ProApp: App {
    @StateObject private var purchaseStore = PurchaseStore()

    init() {
        UserDefaults.standard.register(defaults: [
            "preferredInterfaceLanguage": InterfaceLanguage.english.rawValue,
            "defaultVoiceLanguage": VoiceLanguage.english.rawValue,
            "appAppearance": AppAppearance.system.rawValue,
            "saveCalculatorHistoryEnabled": true,
            "saveTranscriptHistoryEnabled": true
        ])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseStore)
        }
    }
}
