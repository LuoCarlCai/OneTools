import SwiftUI
import UIKit
import AudioToolbox

enum AppFeedbackSound: String, CaseIterable, Identifiable {
    case off
    case click
    case tick
    case pop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off:
            return AppLocalizer.string("Off")
        case .click:
            return AppLocalizer.string("Click")
        case .tick:
            return AppLocalizer.string("Tick")
        case .pop:
            return AppLocalizer.string("Pop")
        }
    }

    var systemSoundID: SystemSoundID? {
        switch self {
        case .off:
            return nil
        case .click:
            return 1104
        case .tick:
            return 1105
        case .pop:
            return 1157
        }
    }
}

enum AppFeedback {
    private static let hapticsKey = "feedbackHapticsEnabled"
    private static let soundKey = "feedbackSoundStyle"

    static var hapticsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: hapticsKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: hapticsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hapticsKey)
        }
    }

    static var soundStyle: AppFeedbackSound {
        get {
            let rawValue = UserDefaults.standard.string(forKey: soundKey) ?? AppFeedbackSound.click.rawValue
            return AppFeedbackSound(rawValue: rawValue) ?? .click
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: soundKey)
        }
    }

    static func selection() {
        play(style: .light)
    }

    static func action() {
        play(style: .medium)
    }

    static func previewHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        triggerHaptic(style: style)
    }

    static func previewSound() {
        playSoundIfNeeded()
    }

    static func success() {
        if hapticsEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
        playSoundIfNeeded()
    }

    static func warning() {
        if hapticsEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        }
        playSoundIfNeeded()
    }

    private static func play(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        triggerHaptic(style: style)
        playSoundIfNeeded()
    }

    private static func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        if hapticsEnabled {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        }
    }

    private static func playSoundIfNeeded() {
        guard let soundID = soundStyle.systemSoundID else { return }
        AudioServicesPlaySystemSound(soundID)
    }
}
