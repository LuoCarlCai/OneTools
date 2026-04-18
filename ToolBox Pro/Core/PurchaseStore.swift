import Foundation
import Combine
import StoreKit

enum PremiumFeature: String, CaseIterable {
    case calculator
    case unitConverter
    case qrToolkit
    case watermark
    case compressor
    case voiceToText

    var title: String {
        switch self {
        case .calculator: return AppLocalizer.string("Calculator")
        case .unitConverter: return AppLocalizer.string("Unit Converter")
        case .qrToolkit: return AppLocalizer.string("QR Toolkit")
        case .watermark: return AppLocalizer.string("Watermark")
        case .compressor: return AppLocalizer.string("Compressor")
        case .voiceToText: return AppLocalizer.string("Voice to Text")
        }
    }
}

enum ProSubscriptionState {
    case inactive
    case active
}

enum ProPlan: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var productID: String {
        switch self {
        case .monthly:
            return PurchaseStore.proMonthlyID
        case .yearly:
            return PurchaseStore.proYearlyID
        }
    }

    var title: String {
        switch self {
        case .monthly:
            return AppLocalizer.string("Monthly")
        case .yearly:
            return AppLocalizer.string("Yearly")
        }
    }

    var displayName: String {
        switch self {
        case .monthly:
            return AppLocalizer.string("Pro Monthly")
        case .yearly:
            return AppLocalizer.string("Pro Yearly")
        }
    }

    var subtitle: String {
        switch self {
        case .monthly:
            return AppLocalizer.string("Auto-renews monthly. Cancel anytime in App Store settings.")
        case .yearly:
            return AppLocalizer.string("Auto-renews yearly. Cancel anytime in App Store settings.")
        }
    }
}

@MainActor
final class PurchaseStore: ObservableObject {
    static let proMonthlyID = "com.carl.toolboxpro.pro.monthly"
    static let proYearlyID = "com.carl.toolboxpro.pro.yearly"
    static let freeUseLimit = 2
    private static let featureUsageKey = "premiumFeatureUsage"

    @Published private(set) var isProUnlocked = false
    @Published private(set) var subscriptionState: ProSubscriptionState = .inactive
    @Published private(set) var products: [ProPlan: Product] = [:]
    @Published private(set) var activePlan: ProPlan?
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isProcessingPurchase = false
    @Published var statusMessage = ""
    private var updatesTask: Task<Void, Never>?

    init(loadStoreKit: Bool = true) {
        guard loadStoreKit else { return }
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await transaction.finish()
                await updateEntitlements()
            }
        }
        Task {
            await refresh()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func refresh() async {
        await requestProducts()
        await updateEntitlements()
    }

    func requestProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let storeProducts = try await Product.products(for: [Self.proMonthlyID, Self.proYearlyID])
            var mapped: [ProPlan: Product] = [:]
            for plan in ProPlan.allCases {
                if let product = storeProducts.first(where: { $0.id == plan.productID }) {
                    mapped[plan] = product
                }
            }
            products = mapped
            if mapped.isEmpty {
                statusMessage = AppLocalizer.string("Product information is unavailable right now.")
            } else if statusMessage == AppLocalizer.string("Product information is unavailable right now.") {
                statusMessage = ""
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func buy(plan: ProPlan) async {
        guard !isProcessingPurchase else { return }
        if isProUnlocked && activePlan == plan {
            statusMessage = AppLocalizer.string("This plan is already active.")
            return
        }
        guard let product = products[plan] else {
            statusMessage = AppLocalizer.string("We could not load this plan yet. Please try again in a moment.")
            return
        }

        isProcessingPurchase = true
        defer { isProcessingPurchase = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await updateEntitlements()
                    statusMessage = AppLocalizer.string("You're all set. %@ is now active.", plan.displayName)
                    await transaction.finish()
                } else {
                    statusMessage = AppLocalizer.string("The purchase finished, but we could not verify it yet.")
                }
            case .userCancelled:
                statusMessage = AppLocalizer.string("Purchase cancelled. Nothing was charged.")
            case .pending:
                statusMessage = AppLocalizer.string("Your purchase is pending approval. We'll unlock Pro as soon as Apple confirms it.")
            @unknown default:
                statusMessage = AppLocalizer.string("We could not complete the purchase right now.")
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func handleBuyTapWhileUnavailable(for plan: ProPlan) async {
        if isProUnlocked && activePlan == plan {
            statusMessage = AppLocalizer.string("This plan is already active.")
            return
        }

        if isLoadingProducts {
            statusMessage = AppLocalizer.string("We are still loading %@ pricing. Please try again in a moment.", plan.title)
            return
        }

        statusMessage = AppLocalizer.string("We could not load this plan yet. Please try again in a moment.")
        await refresh()
    }

    func restorePurchases() async {
        guard !isProcessingPurchase else { return }
        isProcessingPurchase = true
        defer { isProcessingPurchase = false }

        do {
            try await AppStore.sync()
            await updateEntitlements()
            statusMessage = isProUnlocked
                ? AppLocalizer.string("Your active subscription has been restored.")
                : AppLocalizer.string("We could not find an active subscription to restore.")
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func updateEntitlements() async {
        var unlocked = false
        var detectedPlan: ProPlan?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if let plan = ProPlan.allCases.first(where: { $0.productID == transaction.productID }) {
                unlocked = true
                detectedPlan = plan
            }
        }
        isProUnlocked = unlocked
        activePlan = detectedPlan
        subscriptionState = unlocked ? .active : .inactive
        if unlocked, statusMessage == AppLocalizer.string("No previous purchases were found.") {
            statusMessage = ""
        }
    }

    func remainingFreeUses(for feature: PremiumFeature) -> Int {
        // Free-trial counting is temporarily disabled so tools remain fully accessible.
        // Original logic:
        // max(0, Self.freeUseLimit - usageCounts()[feature.rawValue, default: 0])
        0
    }

    func consumeFreeUseIfNeeded(for feature: PremiumFeature) -> Bool {
        // Free-trial consumption is temporarily disabled so usage is never blocked.
        // Original logic:
        // guard !isProUnlocked else { return true }
        // var usage = usageCounts()
        // let current = usage[feature.rawValue, default: 0]
        // guard current < Self.freeUseLimit else { return false }
        // usage[feature.rawValue] = current + 1
        // saveUsageCounts(usage)
        // objectWillChange.send()
        true
    }

    func hasAccess(to feature: PremiumFeature) -> Bool {
        // Always allow access while the free-use restriction is disabled.
        true
    }

    private func usageCounts() -> [String: Int] {
        guard let data = UserDefaults.standard.data(forKey: Self.featureUsageKey),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func saveUsageCounts(_ usage: [String: Int]) {
        guard let data = try? JSONEncoder().encode(usage) else { return }
        UserDefaults.standard.set(data, forKey: Self.featureUsageKey)
    }

    var subscriptionStatusTitle: String {
        switch subscriptionState {
        case .active:
            return AppLocalizer.string("Active")
        case .inactive:
            return AppLocalizer.string("Inactive")
        }
    }

    var paywallPriceText: String {
        if isLoadingProducts {
            return AppLocalizer.string("Loading...")
        }
        if let product = products[.monthly] {
            return product.displayPrice
        }
        return AppLocalizer.string("Unavailable")
    }

    func priceText(for plan: ProPlan) -> String {
        if isLoadingProducts {
            return AppLocalizer.string("Loading...")
        }
        if let product = products[plan] {
            return product.displayPrice
        }
        return AppLocalizer.string("Unavailable")
    }
}
