import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject private var purchaseStore: PurchaseStore
    @AppStorage("calculatorHistory") private var historyStorage = ""
    @AppStorage("saveCalculatorHistoryEnabled") private var saveCalculatorHistoryEnabled = true

    @State private var mode: CalculatorMode = .standard
    @State private var expression = "0"
    @State private var shouldReset = false
    @State private var statusMessage = ""
    @State private var historyRecords: [TaggedHistoryRecord] = []
    @State private var programmerPrimaryInput = "255"
    @State private var programmerSecondaryInput = "15"
    @State private var programmerOperation: ProgrammerOperation = .and
    @State private var dateStart = Date()
    @State private var dateEnd = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var dateOffsetInput = "7"
    @State private var copyMessage = ""
    @State private var copyMessageTint = AppColor.success
    @State private var isLocked = false
    @State private var remainingUses = 0
    private let premiumFeature: PremiumFeature = .calculator

    private let rows: [[String]] = [
        ["C", "(", ")", "⌫"],
        ["7", "8", "9", "/"],
        ["4", "5", "6", "*"],
        ["1", "2", "3", "-"],
        [".", "0", "=", "+"]
    ]

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: AppColor.primary, secondaryTint: AppColor.warning)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if isLocked {
                        FeatureLockedCard(feature: premiumFeature)
                    } else {
                        if !purchaseStore.isProUnlocked && remainingUses > 0 {
                            TrialUsageBanner(remainingUses: remainingUses)
                        }

                        introCard
                        overviewCards
                        modePicker
                        modeContent
                        historyPreview
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(AppLocalizer.string("Calculator"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: CalculatorHistoryView(historyStorage: $historyStorage).hidesTabBarOnPush()) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(AppColor.primary)
                }
                .feedbackOnTap()
            }
        }
        .onAppear {
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
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mode.headline)
                .appFont(size: 18, weight: .bold)
                .foregroundColor(AppColor.primaryText)
            Text(mode.detail)
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

    private var overviewCards: some View {
        HStack(spacing: 12) {
            overviewCard(
                title: AppLocalizer.string("Mode"),
                value: mode.title,
                tint: AppColor.primary
            )
            overviewCard(
                title: AppLocalizer.string("History"),
                value: saveCalculatorHistoryEnabled ? "\(historyRecords.count)" : AppLocalizer.string("Disabled"),
                tint: AppColor.success
            )
        }
    }

    private var modePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CalculatorMode.allCases) { item in
                    Button {
                        AppFeedback.selection()
                        mode = item
                    } label: {
                        Text(item.title)
                            .appFont(size: 14, weight: .bold)
                            .foregroundColor(mode == item ? .white : AppColor.primaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(mode == item ? AppColor.primary : AppColor.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(mode == item ? AppColor.primary : AppColor.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private var modeContent: some View {
        switch mode {
        case .standard:
            display
            keypad
        case .scientific:
            display
            scientificKeypad
            keypad
        case .programmer:
            programmerPanel
        case .date:
            datePanel
        }
    }

    private var display: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Text(mode.displayTitle)
                    .appFont(size: 14, weight: .medium)
                    .foregroundColor(AppColor.secondaryText)

                Spacer()

                Button(AppLocalizer.string("Copy Result")) {
                    copyCalculatorValue(expression)
                }
                .buttonStyle(.plain)
                .appFont(size: 13, weight: .bold)
                .foregroundColor(AppColor.primary)
            }

            Text(expression)
                .appFont(size: 36, weight: .bold)
                .foregroundColor(AppColor.primaryText)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.4)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .appFont(size: 13, weight: .medium)
                    .foregroundColor(AppColor.warning)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            if !copyMessage.isEmpty {
                Text(copyMessage)
                    .appFont(size: 13, weight: .medium)
                    .foregroundColor(copyMessageTint)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .bottomTrailing)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }

    private var scientificKeypad: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

        return LazyVGrid(columns: columns, spacing: 10) {
            scientificButton("π") { insertConstant(Double.pi) }
            scientificButton("e") { insertConstant(M_E) }
            scientificButton("x²") { applyScientificUnary(label: "x²") { $0 * $0 } }
            scientificButton("√x") { applyScientificUnary(label: "√x") { sqrt($0) } }
            scientificButton("1/x") { applyScientificUnary(label: "1/x") { 1 / $0 } }
            scientificButton("%") { applyScientificUnary(label: "%") { $0 / 100 } }
            scientificButton("sin") { applyScientificUnary(label: "sin") { sin($0) } }
            scientificButton("cos") { applyScientificUnary(label: "cos") { cos($0) } }
            scientificButton("tan") { applyScientificUnary(label: "tan") { tan($0) } }
            scientificButton("ln") { applyScientificUnary(label: "ln") { log($0) } }
            scientificButton("log") { applyScientificUnary(label: "log") { log10($0) } }
            scientificButton("±") { applyScientificUnary(label: "±") { -$0 } }
        }
    }

    private var programmerPanel: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text(AppLocalizer.string("Decimal Input"))
                    .appFont(size: 16, weight: .bold)
                    .foregroundColor(AppColor.primaryText)

                TextField(AppLocalizer.string("Enter integer value"), text: $programmerPrimaryInput)
                    .keyboardType(.numbersAndPunctuation)
                    .padding(14)
                    .background(AppColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppColor.border, lineWidth: 1)
                    )
            }

            programmerConversionGrid

            VStack(alignment: .leading, spacing: 12) {
                Text(AppLocalizer.string("Bitwise Operation"))
                    .appFont(size: 16, weight: .bold)
                    .foregroundColor(AppColor.primaryText)

                Picker(AppLocalizer.string("Operation"), selection: $programmerOperation) {
                    ForEach(ProgrammerOperation.allCases) { operation in
                        Text(operation.title).tag(operation)
                    }
                }
                .pickerStyle(.segmented)

                TextField(AppLocalizer.string("Second integer"), text: $programmerSecondaryInput)
                    .keyboardType(.numbersAndPunctuation)
                    .padding(14)
                    .background(AppColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppColor.border, lineWidth: 1)
                    )

                HStack {
                    Text(AppLocalizer.string("Result"))
                        .appFont(size: 15, weight: .bold)
                        .foregroundColor(AppColor.primaryText)
                    Spacer()
                    Text(programmerResultText)
                        .appFont(size: 20, weight: .bold)
                        .foregroundColor(AppColor.primary)
                }

                Button(AppLocalizer.string("Save Result")) {
                    guard consumeFeatureUseIfNeeded() else { return }
                    saveHistoryEntry(programmerHistoryEntry)
                    AppFeedback.success()
                }
                .buttonStyle(.plain)
                .appFont(size: 15, weight: .bold)
                .foregroundColor(AppColor.primary)
                .disabled(programmerResultText == "--")
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

    private var programmerConversionGrid: some View {
        VStack(spacing: 10) {
            programmerValueCard(title: "HEX", value: programmerConverted(base: 16))
            programmerValueCard(title: "DEC", value: programmerConverted(base: 10))
            programmerValueCard(title: "OCT", value: programmerConverted(base: 8))
            programmerValueCard(title: "BIN", value: programmerConverted(base: 2))
        }
    }

    private var datePanel: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text(AppLocalizer.string("Date Difference"))
                    .appFont(size: 16, weight: .bold)
                    .foregroundColor(AppColor.primaryText)

                DatePicker(AppLocalizer.string("Start Date"), selection: $dateStart, displayedComponents: .date)
                DatePicker(AppLocalizer.string("End Date"), selection: $dateEnd, displayedComponents: .date)

                HStack {
                    Text(AppLocalizer.string("Days Between"))
                        .appFont(size: 15, weight: .bold)
                        .foregroundColor(AppColor.primaryText)
                    Spacer()
                    Text("\(daysBetweenDates)")
                        .appFont(size: 22, weight: .bold)
                        .foregroundColor(AppColor.primary)
                }

                Button(AppLocalizer.string("Save Span")) {
                    guard consumeFeatureUseIfNeeded() else { return }
                    saveHistoryEntry(dateSpanHistoryEntry)
                    AppFeedback.success()
                }
                .buttonStyle(.plain)
                .appFont(size: 15, weight: .bold)
                .foregroundColor(AppColor.primary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text(AppLocalizer.string("Add Days"))
                    .appFont(size: 16, weight: .bold)
                    .foregroundColor(AppColor.primaryText)

                TextField(AppLocalizer.string("Number of days"), text: $dateOffsetInput)
                    .keyboardType(.numbersAndPunctuation)
                    .padding(14)
                    .background(AppColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppColor.border, lineWidth: 1)
                    )

                HStack {
                    Text(AppLocalizer.string("Result Date"))
                        .appFont(size: 15, weight: .bold)
                        .foregroundColor(AppColor.primaryText)
                    Spacer()
                    Text(offsetDateText)
                        .appFont(size: 18, weight: .bold)
                        .foregroundColor(AppColor.success)
                }

                Button(AppLocalizer.string("Save Result")) {
                    guard consumeFeatureUseIfNeeded() else { return }
                    saveHistoryEntry(dateOffsetHistoryEntry)
                    AppFeedback.success()
                }
                .buttonStyle(.plain)
                .appFont(size: 15, weight: .bold)
                .foregroundColor(AppColor.primary)
                .disabled(offsetDateText == "--")
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

    private var historyPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(AppLocalizer.string("History"))
                    .appFont(size: 18, weight: .bold)
                    .foregroundColor(AppColor.primaryText)
                Spacer()
                if !historyRecords.isEmpty {
                    NavigationLink(destination: CalculatorHistoryView(historyStorage: $historyStorage).hidesTabBarOnPush()) {
                        Text(AppLocalizer.string("More"))
                            .appFont(size: 14, weight: .bold)
                            .foregroundColor(AppColor.primary)
                    }
                    .feedbackOnTap()
                }
                Button(AppLocalizer.string("Clear")) {
                    AppFeedback.selection()
                    historyStorage = ""
                }
                .disabled(historyRecords.isEmpty)
            }

            if let item = historyRecords.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.text)
                        .appFont(size: 15, weight: .medium)
                        .foregroundColor(AppColor.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

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
                .padding(14)
                .background(AppColor.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Text(AppLocalizer.string("Recent calculations will appear here automatically."))
                    .appFont(size: 14, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(AppColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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

    private var keypad: some View {
        VStack(spacing: 12) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { item in
                        Button {
                            handleTap(item)
                        } label: {
                            Text(item)
                                .appFont(size: 24, weight: .bold)
                                .foregroundColor(foregroundColor(for: item))
                                .frame(maxWidth: .infinity, minHeight: 64)
                                .background(backgroundColor(for: item))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            item == "⌫"
                            ? LongPressGesture(minimumDuration: 0.5).onEnded { _ in expression = "0" }
                            : nil
                        )
                    }
                }
            }
        }
    }

    private func overviewCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .appFont(size: 12, weight: .medium)
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

    private func backgroundColor(for item: String) -> Color {
        if item == "=" { return AppColor.primary }
        if ["+", "-", "*", "/", "C", "⌫", "(", ")"].contains(item) { return AppColor.background }
        return AppColor.surface
    }

    private func foregroundColor(for item: String) -> Color {
        if item == "=" { return .white }
        if ["+", "-", "*", "/", "C", "⌫"].contains(item) { return AppColor.primary }
        return AppColor.primaryText
    }

    private func handleTap(_ item: String) {
        AppFeedback.selection()
        switch item {
        case "C":
            expression = "0"
            statusMessage = ""
            copyMessage = ""
        case "⌫":
            expression = String(expression.dropLast())
            if expression.isEmpty { expression = "0" }
        case "=":
            evaluate()
        default:
            if shouldReset {
                expression = "0"
                shouldReset = false
            }
            statusMessage = ""
            copyMessage = ""
            if expression == "0", !"./*+-()".contains(item) {
                expression = item
            } else {
                expression += item
            }
        }
    }

    private func scientificButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .appFont(size: 18, weight: .bold)
                .foregroundColor(AppColor.primary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(AppColor.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func evaluate() {
        guard consumeFeatureUseIfNeeded() else { return }
        let sanitized = expression.replacingOccurrences(of: "*", with: "×").replacingOccurrences(of: "/", with: "÷")
        do {
            let result = try CalculatorEvaluator.evaluate(expression)
            let output = format(result.doubleValue)
            saveHistoryEntry("\(sanitized) = \(output)")
            expression = output
            shouldReset = true
            statusMessage = ""
            AppFeedback.success()
        } catch {
            statusMessage = AppLocalizer.string("Invalid expression")
        }
    }

    private func applyScientificUnary(label: String, operation: (Double) -> Double) {
        guard consumeFeatureUseIfNeeded() else { return }
        do {
            let current = try CalculatorEvaluator.evaluate(expression).doubleValue
            guard current.isFinite else {
                statusMessage = AppLocalizer.string("Invalid expression")
                return
            }
            let result = operation(current)
            guard result.isFinite else {
                statusMessage = AppLocalizer.string("Invalid expression")
                return
            }
            let output = format(result)
            saveHistoryEntry("\(label)(\(format(current))) = \(output)")
            expression = output
            shouldReset = true
            statusMessage = ""
            AppFeedback.success()
        } catch {
            statusMessage = AppLocalizer.string("Invalid expression")
        }
    }

    private func insertConstant(_ value: Double) {
        statusMessage = ""
        copyMessage = ""
        expression = format(value)
        shouldReset = true
        AppFeedback.selection()
    }

    private func copyCalculatorValue(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "0" || shouldReset else { return }
        UIPasteboard.general.string = trimmed
        AppFeedback.success()
        copyMessage = AppLocalizer.string("Result copied.")
        copyMessageTint = AppColor.success
    }

    private func saveHistoryEntry(_ text: String) {
        guard saveCalculatorHistoryEnabled else { return }
        historyRecords.insert(TaggedHistoryRecord(text: text), at: 0)
        historyStorage = HistoryStorage.saveRecords(historyRecords)
    }

    private func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
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

    private func programmerConverted(base: Int) -> String {
        guard let value = Int(programmerPrimaryInput) else { return "--" }
        switch base {
        case 16: return String(value, radix: 16).uppercased()
        case 10: return "\(value)"
        case 8: return String(value, radix: 8)
        case 2: return String(value, radix: 2)
        default: return "--"
        }
    }

    private func programmerValueCard(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .appFont(size: 13, weight: .bold)
                .foregroundColor(AppColor.secondaryText)
            Spacer()
            Text(value)
                .appFont(size: 17, weight: .bold)
                .foregroundColor(AppColor.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .background(AppColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var programmerResultText: String {
        guard let lhs = Int(programmerPrimaryInput),
              let rhs = Int(programmerSecondaryInput) else { return "--" }
        let result = programmerOperation.apply(lhs: lhs, rhs: rhs)
        return "\(result)"
    }

    private var programmerHistoryEntry: String {
        guard let lhs = Int(programmerPrimaryInput),
              let rhs = Int(programmerSecondaryInput) else { return "" }
        return "\(lhs) \(programmerOperation.symbol) \(rhs) = \(programmerOperation.apply(lhs: lhs, rhs: rhs))"
    }

    private var daysBetweenDates: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: dateStart), to: Calendar.current.startOfDay(for: dateEnd)).day ?? 0
    }

    private var dateSpanHistoryEntry: String {
        "\(formatDate(dateStart)) -> \(formatDate(dateEnd)) = \(daysBetweenDates) \(AppLocalizer.string("days"))"
    }

    private var offsetDateText: String {
        guard let offset = Int(dateOffsetInput),
              let result = Calendar.current.date(byAdding: .day, value: offset, to: dateStart) else { return "--" }
        return formatDate(result)
    }

    private var dateOffsetHistoryEntry: String {
        guard let offset = Int(dateOffsetInput),
              let result = Calendar.current.date(byAdding: .day, value: offset, to: dateStart) else { return "" }
        return "\(formatDate(dateStart)) + \(offset) \(AppLocalizer.string("days")) = \(formatDate(result))"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

private enum CalculatorMode: String, CaseIterable, Identifiable {
    case standard
    case scientific
    case programmer
    case date

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return AppLocalizer.string("Standard")
        case .scientific: return AppLocalizer.string("Scientific")
        case .programmer: return AppLocalizer.string("Programmer")
        case .date: return AppLocalizer.string("Date")
        }
    }

    var headline: String {
        switch self {
        case .standard:
            return AppLocalizer.string("Solve everyday calculations quickly")
        case .scientific:
            return AppLocalizer.string("Use advanced math tools with a familiar keypad")
        case .programmer:
            return AppLocalizer.string("Convert bases and run bitwise operations quickly")
        case .date:
            return AppLocalizer.string("Calculate date spans and future days in one place")
        }
    }

    var detail: String {
        switch self {
        case .standard:
            return AppLocalizer.string("Use the standard keypad, review recent results, and keep quick math ready offline.")
        case .scientific:
            return AppLocalizer.string("Add roots, logs, trigonometry, constants, and percentages without leaving the calculator.")
        case .programmer:
            return AppLocalizer.string("View integer values in binary, octal, decimal, and hex, then save bitwise results to history.")
        case .date:
            return AppLocalizer.string("See the number of days between dates or add a day offset and keep the result in history.")
        }
    }

    var displayTitle: String {
        switch self {
        case .standard:
            return AppLocalizer.string("Standard Calculator")
        case .scientific:
            return AppLocalizer.string("Scientific Calculator")
        case .programmer:
            return AppLocalizer.string("Programmer Calculator")
        case .date:
            return AppLocalizer.string("Date Calculator")
        }
    }
}

private enum ProgrammerOperation: String, CaseIterable, Identifiable {
    case and, or, xor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .and: return "AND"
        case .or: return "OR"
        case .xor: return "XOR"
        }
    }

    var symbol: String { title }

    func apply(lhs: Int, rhs: Int) -> Int {
        switch self {
        case .and: return lhs & rhs
        case .or: return lhs | rhs
        case .xor: return lhs ^ rhs
        }
    }
}

private enum CalculatorEvaluator {
    static func evaluate(_ expression: String) throws -> NSNumber {
        var parser = ExpressionParser(expression: expression)
        let value = try parser.parse()
        return NSNumber(value: value)
    }

    private struct ExpressionParser {
        let tokens: [Character]
        var index: Int = 0

        init(expression: String) {
            self.tokens = Array(expression.replacingOccurrences(of: " ", with: ""))
        }

        mutating func parse() throws -> Double {
            guard !tokens.isEmpty else { throw ParserError.invalidExpression }
            let value = try parseExpression()
            guard index == tokens.count else { throw ParserError.invalidExpression }
            return value
        }

        mutating func parseExpression() throws -> Double {
            var value = try parseTerm()

            while let token = currentToken {
                if token == "+" || token == "-" {
                    index += 1
                    let rhs = try parseTerm()
                    value = token == "+" ? value + rhs : value - rhs
                } else {
                    break
                }
            }

            return value
        }

        mutating func parseTerm() throws -> Double {
            var value = try parseFactor()

            while let token = currentToken {
                if token == "*" || token == "/" {
                    index += 1
                    let rhs = try parseFactor()
                    if token == "/" {
                        guard rhs != 0 else { throw ParserError.divisionByZero }
                        value /= rhs
                    } else {
                        value *= rhs
                    }
                } else {
                    break
                }
            }

            return value
        }

        mutating func parseFactor() throws -> Double {
            guard let token = currentToken else { throw ParserError.invalidExpression }

            if token == "-" {
                index += 1
                return -(try parseFactor())
            }

            if token == "(" {
                index += 1
                let value = try parseExpression()
                guard currentToken == ")" else { throw ParserError.invalidExpression }
                index += 1
                return value
            }

            return try parseNumber()
        }

        mutating func parseNumber() throws -> Double {
            let start = index
            var hasDecimalPoint = false

            while let token = currentToken {
                if token.isNumber {
                    index += 1
                } else if token == "." && !hasDecimalPoint {
                    hasDecimalPoint = true
                    index += 1
                } else {
                    break
                }
            }

            guard start != index else { throw ParserError.invalidExpression }
            let string = String(tokens[start..<index])
            guard let value = Double(string) else { throw ParserError.invalidExpression }
            return value
        }

        var currentToken: Character? {
            guard index < tokens.count else { return nil }
            return tokens[index]
        }
    }

    private enum ParserError: Error {
        case invalidExpression
        case divisionByZero
    }
}

private struct CalculatorHistoryView: View {
    @Binding var historyStorage: String
    @State private var records: [TaggedHistoryRecord] = []
    @State private var currentPage = 0
    private let pageSize = 10

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: AppColor.primary, secondaryTint: AppColor.success)

            ScrollView {
                VStack(spacing: 14) {
                    if records.isEmpty {
                        Text(AppLocalizer.string("Recent calculations will appear here automatically."))
                            .appFont(size: 14, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        ForEach(pageIndices, id: \.self) { index in
                            TaggedHistoryRow(record: $records[index], tint: AppColor.primary) {
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
