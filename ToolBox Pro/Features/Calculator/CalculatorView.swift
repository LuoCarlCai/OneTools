import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject private var purchaseStore: PurchaseStore
    @AppStorage("calculatorHistory") private var historyStorage = ""
    @AppStorage("saveCalculatorHistoryEnabled") private var saveCalculatorHistoryEnabled = true

    @State private var expression = "0"
    @State private var shouldReset = false
    @State private var historyRecords: [TaggedHistoryRecord] = []

    private let rows: [[String]] = [
        ["C", "(", ")", "⌫"],
        ["7", "8", "9", "/"],
        ["4", "5", "6", "*"],
        ["1", "2", "3", "-"],
        [".", "0", "=", "+"]
    ]

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    introCard
                    overviewCards
                    display
                    keypad

                    if !purchaseStore.isProUnlocked {
                        adPlaceholder
                    }

                    historyPreview
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
            }
        }
        .onAppear {
            historyRecords = HistoryStorage.loadRecords(from: historyStorage)
        }
        .onChange(of: historyStorage) { value in
            historyRecords = HistoryStorage.loadRecords(from: value)
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppLocalizer.string("Solve everyday calculations quickly"))
                .appFont(size: 18, weight: .bold)
                .foregroundColor(AppColor.primaryText)
            Text(AppLocalizer.string("Use the standard keypad, review recent results, and keep quick math ready offline."))
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
                value: AppLocalizer.string("Standard"),
                tint: AppColor.primary
            )
            overviewCard(
                title: AppLocalizer.string("History"),
                value: saveCalculatorHistoryEnabled ? (historyRecords.isEmpty ? AppLocalizer.string("Off") : "\(historyRecords.count)") : AppLocalizer.string("Disabled"),
                tint: AppColor.success
            )
        }
    }

    private var display: some View {
        VStack(alignment: .trailing, spacing: 12) {
            Text(AppLocalizer.string("Standard Calculator"))
                .appFont(size: 14, weight: .medium)
                .foregroundColor(AppColor.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(expression)
                .appFont(size: 36, weight: .bold)
                .foregroundColor(AppColor.primaryText)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.4)
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
                }
                Button(AppLocalizer.string("Clear")) {
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

    private var adPlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppLocalizer.string("Upgrade for a cleaner workspace"))
                .appFont(size: 16, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            Text(AppLocalizer.string("Remove banner ads across core tools and restore Pro anytime with the same Apple ID."))
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
        switch item {
        case "C":
            expression = "0"
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
            if expression == "0", !"./*+-()".contains(item) {
                expression = item
            } else {
                expression += item
            }
        }
    }

    private func evaluate() {
        let sanitized = expression.replacingOccurrences(of: "*", with: "×").replacingOccurrences(of: "/", with: "÷")
        let eval = NSExpression(format: expression)
        if let result = eval.expressionValue(with: nil, context: nil) as? NSNumber {
            let output = format(result.doubleValue)
            if saveCalculatorHistoryEnabled {
                historyRecords.insert(TaggedHistoryRecord(text: "\(sanitized) = \(output)"), at: 0)
                historyStorage = HistoryStorage.saveRecords(historyRecords)
            }
            expression = output
            shouldReset = true
        }
    }

    private func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

private struct CalculatorHistoryView: View {
    @Binding var historyStorage: String
    @State private var records: [TaggedHistoryRecord] = []
    @State private var currentPage = 0
    private let pageSize = 10

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

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
                currentPage = max(currentPage - 1, 0)
            }
            .disabled(currentPage == 0)

            Spacer()

            Text(AppLocalizer.string("Page %@ of %@", "\(currentPage + 1)", "\(totalPages)"))
                .appFont(size: 13, weight: .medium)
                .foregroundColor(AppColor.secondaryText)

            Spacer()

            Button(AppLocalizer.string("Next")) {
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
