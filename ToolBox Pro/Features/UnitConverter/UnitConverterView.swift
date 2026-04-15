import SwiftUI

struct UnitConverterView: View {
    @EnvironmentObject private var purchaseStore: PurchaseStore
    @State private var category = ConversionCategory.all.first!
    @State private var fromUnit = ConversionCategory.all.first!.units.first!
    @State private var toUnit = ConversionCategory.all.first!.units.dropFirst().first!
    @State private var input = "1"
    @State private var isLocked = false
    @State private var remainingUses = 0
    @State private var didConsumeTrialInSession = false
    private let premiumFeature: PremiumFeature = .unitConverter

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: AppColor.success, secondaryTint: AppColor.primary)

            ScrollView {
                VStack(spacing: 18) {
                    if isLocked {
                        FeatureLockedCard(feature: premiumFeature)
                    } else {
                        if !purchaseStore.isProUnlocked && remainingUses > 0 {
                            TrialUsageBanner(remainingUses: remainingUses)
                        }

                        introCard
                        Picker("", selection: $category) {
                            ForEach(ConversionCategory.all) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: category) { value in
                            fromUnit = value.units[0]
                            toUnit = value.units[1]
                        }

                        categorySummary
                        converterCard
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(AppLocalizer.string("Unit Converter"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshAccessState() }
        .onChange(of: purchaseStore.isProUnlocked) { unlocked in
            if unlocked {
                isLocked = false
                remainingUses = 0
            } else {
                refreshAccessState()
            }
        }
        .onChange(of: input) { _ in consumeFeatureUseIfNeeded() }
        .onChange(of: category) { _ in consumeFeatureUseIfNeeded() }
        .onChange(of: fromUnit) { _ in consumeFeatureUseIfNeeded() }
        .onChange(of: toUnit) { _ in consumeFeatureUseIfNeeded() }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppLocalizer.string("Convert common units in one place"))
                .appFont(size: 18, weight: .bold)
                .foregroundColor(AppColor.primaryText)
            Text(AppLocalizer.string("Switch categories, pick your units, and get a clean result as you type."))
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

    private var categorySummary: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(category.title)
                    .appFont(size: 18, weight: .bold)
                    .foregroundColor(AppColor.primaryText)
                Text(category.subtitle)
                    .appFont(size: 14, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Text("\(category.units.count) \(AppLocalizer.string("Units"))")
                .appFont(size: 13, weight: .bold)
                .foregroundColor(category.tint)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(category.tint.opacity(0.14))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }

    private var converterCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(AppLocalizer.string("Value"))
                    .appFont(size: 15, weight: .bold)
                    .foregroundColor(AppColor.primaryText)

                TextField(AppLocalizer.string("Value"), text: $input)
                    .keyboardType(.decimalPad)
                    .padding(14)
                    .background(AppColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppColor.border, lineWidth: 1)
                    )
            }

            VStack(spacing: 12) {
                conversionUnitCard(title: AppLocalizer.string("From"), unit: $fromUnit)

                        Button {
                            AppFeedback.selection()
                            swap(&fromUnit, &toUnit)
                        } label: {
                    Label(AppLocalizer.string("Swap"), systemImage: "arrow.up.arrow.down")
                        .appFont(size: 15, weight: .bold)
                        .foregroundColor(AppColor.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColor.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppColor.border, lineWidth: 1)
                        )
                }

                conversionUnitCard(title: AppLocalizer.string("To"), unit: $toUnit)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(AppLocalizer.string("Result"))
                    .appFont(size: 16, weight: .bold)
                Text(resultText)
                    .appFont(size: 28, weight: .bold)
                    .foregroundColor(AppColor.primary)
                Text(resultDetail)
                    .appFont(size: 14, weight: .regular)
                    .foregroundColor(AppColor.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppColor.background)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppColor.border, lineWidth: 1)
            )
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }

    private func conversionUnitCard(title: String, unit: Binding<ConversionUnit>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .appFont(size: 15, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            Picker(title, selection: unit) {
                ForEach(category.units) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.menu)
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

    private var resultText: String {
        guard let value = Double(input) else { return "--" }
        let converted = convertedValue(from: value)
        return String(format: "%.4f %@", converted, toUnit.symbol)
    }

    private var resultDetail: String {
        guard let value = Double(input) else {
            return AppLocalizer.string("Enter a numeric value to convert.")
        }

        return AppLocalizer.string("%@ %@ equals %@ %@", formattedValue(value), fromUnit.symbol, formattedValue(convertedValue(from: value)), toUnit.symbol)
    }

    private func convertedValue(from value: Double) -> Double {
        if category.id == "temperature" {
            let celsius = fromUnit.temperatureToCelsius(value)
            return toUnit.celsiusToTemperature(celsius)
        }

        let base = value * fromUnit.factor
        return base / toUnit.factor
    }

    private func formattedValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 0
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

    private func consumeFeatureUseIfNeeded() {
        guard !didConsumeTrialInSession else { return }
        guard !purchaseStore.isProUnlocked else { return }
        guard purchaseStore.consumeFreeUseIfNeeded(for: premiumFeature) else {
            refreshAccessState()
            return
        }
        didConsumeTrialInSession = true
        refreshAccessState()
    }
}

struct ConversionCategory: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let units: [ConversionUnit]
    let tint: Color

    static var all: [ConversionCategory] {
        [
            ConversionCategory(id: "length", title: AppLocalizer.string("Length"), subtitle: AppLocalizer.string("Distance, screen sizes, and travel measurements."), units: [
                ConversionUnit(id: "meter", title: AppLocalizer.string("Meter"), symbol: "m", factor: 1),
                ConversionUnit(id: "kilometer", title: AppLocalizer.string("Kilometer"), symbol: "km", factor: 1000),
                ConversionUnit(id: "inch", title: AppLocalizer.string("Inch"), symbol: "in", factor: 0.0254),
                ConversionUnit(id: "foot", title: AppLocalizer.string("Foot"), symbol: "ft", factor: 0.3048)
            ], tint: AppColor.primary),
            ConversionCategory(id: "weight", title: AppLocalizer.string("Weight"), subtitle: AppLocalizer.string("Packages, groceries, and body weight."), units: [
                ConversionUnit(id: "kilogram", title: AppLocalizer.string("Kilogram"), symbol: "kg", factor: 1),
                ConversionUnit(id: "gram", title: AppLocalizer.string("Gram"), symbol: "g", factor: 0.001),
                ConversionUnit(id: "pound", title: AppLocalizer.string("Pound"), symbol: "lb", factor: 0.453592),
                ConversionUnit(id: "ounce", title: AppLocalizer.string("Ounce"), symbol: "oz", factor: 0.0283495)
            ], tint: AppColor.success),
            ConversionCategory(id: "area", title: AppLocalizer.string("Area"), subtitle: AppLocalizer.string("Rooms, land, and surface measurements."), units: [
                ConversionUnit(id: "square-meter", title: AppLocalizer.string("Square Meter"), symbol: "m²", factor: 1),
                ConversionUnit(id: "square-kilometer", title: AppLocalizer.string("Square Kilometer"), symbol: "km²", factor: 1_000_000),
                ConversionUnit(id: "square-foot", title: AppLocalizer.string("Square Foot"), symbol: "ft²", factor: 0.092903),
                ConversionUnit(id: "acre", title: AppLocalizer.string("Acre"), symbol: "ac", factor: 4046.8564224)
            ], tint: AppColor.warning),
            ConversionCategory(id: "temperature", title: AppLocalizer.string("Temperature"), subtitle: AppLocalizer.string("Weather, cooking, and equipment readings."), units: [
                ConversionUnit(id: "celsius", title: AppLocalizer.string("Celsius"), symbol: "°C", factor: 1),
                ConversionUnit(id: "fahrenheit", title: AppLocalizer.string("Fahrenheit"), symbol: "°F", factor: 1.8),
                ConversionUnit(id: "kelvin", title: AppLocalizer.string("Kelvin"), symbol: "K", factor: 1)
            ], tint: Color(hex: 0xEF4444)),
            ConversionCategory(id: "volume", title: AppLocalizer.string("Volume"), subtitle: AppLocalizer.string("Cooking, bottles, and storage capacity."), units: [
                ConversionUnit(id: "liter", title: AppLocalizer.string("Liter"), symbol: "L", factor: 1),
                ConversionUnit(id: "milliliter", title: AppLocalizer.string("Milliliter"), symbol: "mL", factor: 0.001),
                ConversionUnit(id: "gallon", title: AppLocalizer.string("Gallon"), symbol: "gal", factor: 3.78541),
                ConversionUnit(id: "cup", title: AppLocalizer.string("Cup"), symbol: "cup", factor: 0.236588)
            ], tint: Color(hex: 0x0EA5A8)),
            ConversionCategory(id: "time", title: AppLocalizer.string("Time"), subtitle: AppLocalizer.string("From seconds to long-duration planning."), units: [
                ConversionUnit(id: "second", title: AppLocalizer.string("Second"), symbol: "s", factor: 1),
                ConversionUnit(id: "minute", title: AppLocalizer.string("Minute"), symbol: "min", factor: 60),
                ConversionUnit(id: "hour", title: AppLocalizer.string("Hour"), symbol: "h", factor: 3600),
                ConversionUnit(id: "day", title: AppLocalizer.string("Day"), symbol: "d", factor: 86400)
            ], tint: Color(hex: 0x6366F1)),
            ConversionCategory(id: "speed", title: AppLocalizer.string("Speed"), subtitle: AppLocalizer.string("Driving, fitness, and delivery speed."), units: [
                ConversionUnit(id: "meter-per-second", title: AppLocalizer.string("Meter per Second"), symbol: "m/s", factor: 1),
                ConversionUnit(id: "kilometer-per-hour", title: AppLocalizer.string("Kilometer per Hour"), symbol: "km/h", factor: 0.277778),
                ConversionUnit(id: "mile-per-hour", title: AppLocalizer.string("Mile per Hour"), symbol: "mph", factor: 0.44704),
                ConversionUnit(id: "knot", title: AppLocalizer.string("Knot"), symbol: "kn", factor: 0.514444)
            ], tint: Color(hex: 0x8B5CF6))
        ]
    }
}

struct ConversionUnit: Identifiable, Hashable {
    let id: String
    let title: String
    let symbol: String
    let factor: Double

    func temperatureToCelsius(_ value: Double) -> Double {
        switch id {
        case "fahrenheit":
            return (value - 32) * 5 / 9
        case "kelvin":
            return value - 273.15
        default:
            return value
        }
    }

    func celsiusToTemperature(_ value: Double) -> Double {
        switch id {
        case "fahrenheit":
            return (value * 9 / 5) + 32
        case "kelvin":
            return value + 273.15
        default:
            return value
        }
    }
}
