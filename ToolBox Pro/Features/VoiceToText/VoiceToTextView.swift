import SwiftUI
import Combine
import AVFoundation
import Speech
import UIKit

struct VoiceToTextView: View {
    @EnvironmentObject private var purchaseStore: PurchaseStore
    @StateObject private var recorder = VoiceToTextRecorder()
    @AppStorage("voiceToTextHistory") private var historyStorage = ""
    @AppStorage("saveTranscriptHistoryEnabled") private var saveTranscriptHistoryEnabled = true
    @AppStorage("defaultVoiceLanguage") private var defaultVoiceLanguageRawValue = VoiceLanguage.english.rawValue
    @State private var selectedLanguage: VoiceLanguage = .english
    @State private var copyMessage = ""
    @State private var copyMessageTint = AppColor.success
    @State private var isShowingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var historyRecords: [TaggedHistoryRecord] = []
    @State private var isLocked = false
    @State private var remainingUses = 0
    private let premiumFeature: PremiumFeature = .voiceToText

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: Color(hex: 0xEC4899), secondaryTint: AppColor.warning)

            ScrollView {
                VStack(spacing: 18) {
                    if isLocked {
                        FeatureLockedCard(feature: premiumFeature)
                    } else {
                        if !purchaseStore.isProUnlocked && remainingUses > 0 {
                            TrialUsageBanner(remainingUses: remainingUses)
                        }

                        introCard
                        statusOverview
                        languagePicker
                        recordButton
                        transcriptSection
                        historySection
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(AppLocalizer.string("Voice to Text"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: VoiceTranscriptHistoryView(historyStorage: $historyStorage).hidesTabBarOnPush()) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(AppColor.primary)
                }
                .feedbackOnTap()
            }
        }
        .onChange(of: selectedLanguage) { recorder.setLanguage($0) }
        .onAppear {
            let language = VoiceLanguage(rawValue: defaultVoiceLanguageRawValue) ?? .english
            selectedLanguage = language
            recorder.setLanguage(language)
            historyRecords = HistoryStorage.loadRecords(from: historyStorage)
            refreshAccessState()
        }
        .onChange(of: historyStorage) { value in
            historyRecords = HistoryStorage.loadRecords(from: value)
        }
        .onChange(of: purchaseStore.isProUnlocked) { unlocked in
            if unlocked {
                isLocked = false
                remainingUses = 0
            } else {
                refreshAccessState()
            }
        }
        .onDisappear {
            recorder.stopRecording(savedToHistory: false)
            recorder.transcript = ""
            copyMessage = ""
        }
        .background(
            ShareSheetPresenter(
                isPresented: $isShowingShareSheet,
                items: shareItems
            )
        )
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppLocalizer.string("Capture speech as text"))
                .appFont(size: 18, weight: .bold)
                .foregroundColor(AppColor.primaryText)
            Text(AppLocalizer.string("Record voice notes, copy the transcript, and keep recent results ready in history."))
                .appFont(size: 14, weight: .regular)
                .foregroundColor(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }

    private var statusOverview: some View {
        HStack(spacing: 14) {
            overviewChip(title: AppLocalizer.string("Language"), value: selectedLanguage.title, tint: AppColor.primary)
            overviewChip(title: AppLocalizer.string("Status"), value: recorder.isRecording ? AppLocalizer.string("Live") : AppLocalizer.string("Idle"), tint: recorder.isRecording ? AppColor.warning : AppColor.success)
            overviewChip(title: AppLocalizer.string("History"), value: saveTranscriptHistoryEnabled ? "\(historyRecords.count)" : AppLocalizer.string("Disabled"), tint: AppColor.success)
        }
    }

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalizer.string("Language"))
                .appFont(size: 18, weight: .bold)
            Menu {
                ForEach(VoiceLanguage.allCases) { language in
                    Button(language.title) {
                        AppFeedback.selection()
                        selectedLanguage = language
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .foregroundColor(AppColor.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedLanguage.title)
                            .foregroundColor(AppColor.primaryText)
                        Text(AppLocalizer.string("Default: %@", (VoiceLanguage(rawValue: defaultVoiceLanguageRawValue) ?? .english).title))
                            .appFont(size: 13, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(AppColor.secondaryText)
                }
                .padding(14)
                .background(AppColor.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var recordButton: some View {
        VStack(spacing: 14) {
            Button {
                toggleRecording()
            } label: {
                ZStack {
                    Circle()
                        .stroke((recorder.isRecording ? AppColor.warning : AppColor.primary).opacity(0.18), lineWidth: 18)
                        .frame(width: 156, height: 156)
                    Circle()
                        .fill(recorder.isRecording ? AppColor.warning : AppColor.primary)
                        .frame(width: 132, height: 132)
                    Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            Text(recorder.isRecording ? AppLocalizer.string("Recording...") : AppLocalizer.string("Tap to start recording"))
                .appFont(size: 18, weight: .bold)
            Text(recorder.statusMessage)
                .appFont(size: 14, weight: .regular)
                .foregroundColor(AppColor.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)

            if recorder.isRecording {
                Text(AppLocalizer.string("Speak naturally. The transcript updates as you talk."))
                    .appFont(size: 13, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentTranscript.isEmpty ? AppLocalizer.string("Current Content") : AppLocalizer.string("Current Translated Content"))
                        .appFont(size: 18, weight: .bold)

                    Text(currentTranscript.isEmpty
                         ? AppLocalizer.string("Current content will appear here after you start recording.")
                         : AppLocalizer.string("Current translated text is ready to copy or save."))
                        .appFont(size: 13, weight: .regular)
                        .foregroundColor(AppColor.secondaryText)
                }
                Spacer()
                if !currentTranscript.isEmpty {
                    Button(AppLocalizer.string("Clear")) {
                        AppFeedback.selection()
                        recorder.transcript = ""
                        copyMessage = ""
                    }
                    .foregroundColor(AppColor.secondaryText)
                }
            }

            Text(currentTranscript.isEmpty ? AppLocalizer.string("Your live transcript will appear here in real time for the selected language.") : currentTranscript)
                .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                .padding(14)
                .background(AppColor.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

            LazyVGrid(columns: columns, spacing: 12) {
                Button(AppLocalizer.string("Copy")) { copyTranscript() }
                    .buttonStyle(VoiceActionButtonStyle(color: AppColor.primary))
                    .disabled(currentTranscript.isEmpty)

                Button(AppLocalizer.string("Share")) { shareTranscript() }
                    .buttonStyle(VoiceActionButtonStyle(color: AppColor.warning))
                    .disabled(currentTranscript.isEmpty)

                Button(AppLocalizer.string("Export TXT")) { exportTranscript() }
                    .buttonStyle(VoiceActionButtonStyle(color: Color(hex: 0x6366F1)))
                    .disabled(currentTranscript.isEmpty)

                Button(AppLocalizer.string("Save")) {
                    if saveCurrentTranscriptIfNeeded(showFeedback: true) {
                        AppFeedback.success()
                    }
                }
                .buttonStyle(VoiceActionButtonStyle(color: AppColor.success))
                .disabled(!saveTranscriptHistoryEnabled || currentTranscript.isEmpty)
            }

            if !copyMessage.isEmpty {
                Text(copyMessage)
                    .foregroundColor(copyMessageTint)
                    .appFont(size: 14, weight: .medium)
            }
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(AppLocalizer.string("History"))
                    .appFont(size: 18, weight: .bold)
                Spacer()
                if !historyRecords.isEmpty {
                    NavigationLink(destination: VoiceTranscriptHistoryView(historyStorage: $historyStorage).hidesTabBarOnPush()) {
                        Text(AppLocalizer.string("More"))
                            .appFont(size: 14, weight: .bold)
                            .foregroundColor(AppColor.primary)
                    }
                    .feedbackOnTap()
                }
                Button(AppLocalizer.string("Clear")) {
                    AppFeedback.selection()
                    historyStorage = ""
                    copyMessage = ""
                }
                    .disabled(historyRecords.isEmpty)
            }

            ForEach(historyRecords.prefix(1)) { item in
                Button {
                    UIPasteboard.general.string = item.text
                    AppFeedback.success()
                    copyMessage = AppLocalizer.string("Copied from history.")
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(AppColor.success.opacity(0.14))
                                .frame(width: 40, height: 40)
                            Image(systemName: "waveform")
                                .foregroundColor(AppColor.success)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.text)
                                .foregroundColor(AppColor.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(3)

                            Text(AppLocalizer.string("Tap to copy"))
                                .appFont(size: 13, weight: .regular)
                                .foregroundColor(AppColor.secondaryText)
                            if !item.tag.isEmpty {
                                Text(item.tag)
                                    .appFont(size: 12, weight: .bold)
                                    .foregroundColor(AppColor.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AppColor.primary.opacity(0.14))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(12)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppColor.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            if historyRecords.isEmpty {
                Text(AppLocalizer.string("Saved transcripts will appear here."))
                    .appFont(size: 14, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var currentTranscript: String {
        recorder.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func toggleRecording() {
        copyMessage = ""
        if recorder.isRecording {
            AppFeedback.warning()
            let saved = saveCurrentTranscriptIfNeeded(showFeedback: false)
            recorder.stopRecording(savedToHistory: saved)
        } else {
            guard consumeFeatureUseIfNeeded() else { return }
            Task {
                AppFeedback.action()
                await recorder.startRecording()
            }
        }
    }

    private func copyTranscript() {
        guard !currentTranscript.isEmpty else { return }
        UIPasteboard.general.string = currentTranscript
        AppFeedback.success()
        copyMessage = AppLocalizer.string("Copied to clipboard.")
        copyMessageTint = AppColor.success
    }

    private func shareTranscript() {
        guard !currentTranscript.isEmpty else { return }
        AppFeedback.action()
        shareItems = [currentTranscript]
        isShowingShareSheet = true
    }

    private func exportTranscript() {
        guard !currentTranscript.isEmpty else { return }
        guard let url = exportTranscriptFileURL() else {
            copyMessage = AppLocalizer.string("Could not prepare the text file.")
            copyMessageTint = AppColor.warning
            return
        }
        AppFeedback.action()
        shareItems = [url]
        isShowingShareSheet = true
    }

    private func exportTranscriptFileURL() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let filename = "OneTools-Transcript-\(formatter.string(from: Date())).txt"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try currentTranscript.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private func saveCurrentTranscriptIfNeeded(showFeedback: Bool) -> Bool {
        guard saveTranscriptHistoryEnabled else {
            if showFeedback {
                copyMessage = AppLocalizer.string("Turn on transcript history in Privacy to save this.")
                copyMessageTint = AppColor.warning
            }
            return false
        }

        let trimmed = currentTranscript
        guard !trimmed.isEmpty else { return false }

        if historyRecords.first?.text == trimmed {
            if showFeedback {
                copyMessage = AppLocalizer.string("Already saved in history.")
                copyMessageTint = AppColor.secondaryText
            }
            return false
        }

        historyRecords.insert(TaggedHistoryRecord(text: trimmed), at: 0)
        historyStorage = HistoryStorage.saveRecords(historyRecords)
        if showFeedback {
            copyMessage = AppLocalizer.string("Saved to history.")
            copyMessageTint = AppColor.success
        }
        return true
    }

    private func overviewChip(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .appFont(size: 13, weight: .medium)
                .foregroundColor(AppColor.secondaryText)
            Text(value)
                .appFont(size: 16, weight: .bold)
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

    private func refreshAccessState() {
        guard !purchaseStore.isProUnlocked else {
            isLocked = false
            remainingUses = 0
            return
        }
        isLocked = !purchaseStore.hasAccess(to: premiumFeature)
        remainingUses = purchaseStore.remainingFreeUses(for: premiumFeature)
    }

    private func consumeFeatureUseIfNeeded() -> Bool {
        guard !purchaseStore.isProUnlocked else { return true }
        guard purchaseStore.consumeFreeUseIfNeeded(for: premiumFeature) else {
            refreshAccessState()
            return false
        }
        refreshAccessState()
        return true
    }
}

private struct VoiceTranscriptHistoryView: View {
    @Binding var historyStorage: String
    @State private var records: [TaggedHistoryRecord] = []
    @State private var currentPage = 0
    private let pageSize = 10

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: Color(hex: 0xEC4899), secondaryTint: AppColor.warning)

            ScrollView {
                VStack(spacing: 14) {
                    if records.isEmpty {
                        Text(AppLocalizer.string("Saved transcripts will appear here."))
                            .appFont(size: 14, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        ForEach(pageIndices, id: \.self) { index in
                            TaggedHistoryRow(record: $records[index], tint: AppColor.success) {
                                records.remove(at: index)
                            }
                        }

                        paginationControls
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(AppLocalizer.string("History"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            records = HistoryStorage.loadRecords(from: historyStorage)
        }
        .onChange(of: records) { value in
            currentPage = min(currentPage, max(totalPages - 1, 0))
            historyStorage = HistoryStorage.saveRecords(value)
        }
    }

    private var totalPages: Int {
        max(Int(ceil(Double(records.count) / Double(pageSize))), 1)
    }

    private var pageIndices: [Int] {
        guard !records.isEmpty else { return [] }
        let start = currentPage * pageSize
        let end = min(start + pageSize, records.count)
        guard start < end else { return [] }
        return Array(start..<end)
    }

    private var paginationControls: some View {
        HStack(spacing: 12) {
            Button(AppLocalizer.string("Previous")) {
                AppFeedback.selection()
                currentPage = max(currentPage - 1, 0)
            }
            .disabled(currentPage == 0)

            Spacer()

            Text(AppLocalizer.string("Page %@ of %@", "\(currentPage + 1)", "\(totalPages)"))
                .appFont(size: 13, weight: .medium)
                .foregroundColor(AppColor.secondaryText)

            Spacer()

            Button(AppLocalizer.string("Next")) {
                AppFeedback.selection()
                currentPage = min(currentPage + 1, totalPages - 1)
            }
            .disabled(currentPage >= totalPages - 1)
        }
        .foregroundColor(AppColor.primary)
        .padding(14)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }
}

private struct VoiceActionButtonStyle: ButtonStyle {
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

enum VoiceLanguage: String, CaseIterable, Identifiable {
    case english = "en-US"
    case spanish = "es-ES"
    case french = "fr-FR"
    case german = "de-DE"
    case portuguese = "pt-BR"
    case japanese = "ja-JP"
    case chinese = "zh-CN"
    case korean = "ko-KR"

    var id: String { rawValue }
    var title: String {
        switch self {
        case .english: return AppLocalizer.string("English")
        case .spanish: return AppLocalizer.string("Spanish")
        case .french: return AppLocalizer.string("French")
        case .german: return AppLocalizer.string("German")
        case .portuguese: return AppLocalizer.string("Portuguese (BR)")
        case .japanese: return AppLocalizer.string("Japanese")
        case .chinese: return AppLocalizer.string("Chinese (Simplified)")
        case .korean: return AppLocalizer.string("Korean")
        }
    }
}

@MainActor
final class VoiceToTextRecorder: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var statusMessage = ""

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: VoiceLanguage.english.rawValue))

    func setLanguage(_ language: VoiceLanguage) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language.rawValue))
    }

    func startRecording() async {
        transcript = ""
        statusMessage = AppLocalizer.string("Listening...")

        guard await requestSpeechRecognitionPermission() else {
            statusMessage = AppLocalizer.string("Speech recognition access is required.")
            return
        }

        guard await requestMicrophonePermission() else {
            statusMessage = AppLocalizer.string("Microphone access is required.")
            return
        }

        guard speechRecognizer != nil else {
            statusMessage = AppLocalizer.string("Voice recognition is unavailable for this language right now.")
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest else { return }
            let inputNode = audioEngine.inputNode
            recognitionRequest.shouldReportPartialResults = true

            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    self.statusMessage = AppLocalizer.string("Listening...")
                }
                if error != nil {
                    self.stopRecording(savedToHistory: false)
                }
            }

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func stopRecording(savedToHistory: Bool) {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
        statusMessage = savedToHistory ? AppLocalizer.string("Saved to history.") : AppLocalizer.string("Ready")
    }

    private func requestSpeechRecognitionPermission() async -> Bool {
        let currentStatus = SFSpeechRecognizer.authorizationStatus()
        switch currentStatus {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        @unknown default:
            return false
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                audioSession.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }
}
