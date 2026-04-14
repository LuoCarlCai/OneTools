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

@MainActor
final class PurchaseStore: ObservableObject {
    static let proMonthlyID = "com.carl.toolboxpro.pro.monthly"
    static let freeUseLimit = 2
    private static let featureUsageKey = "premiumFeatureUsage"

    @Published private(set) var isProUnlocked = false
    @Published private(set) var subscriptionState: ProSubscriptionState = .inactive
    @Published private(set) var product: Product?
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
        do {
            product = try await Product.products(for: [Self.proMonthlyID]).first
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func buy() async {
        guard let product else {
            statusMessage = AppLocalizer.string("Product information is unavailable right now.")
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await updateEntitlements()
                    statusMessage = AppLocalizer.string("Subscription is active.")
                    await transaction.finish()
                } else {
                    statusMessage = AppLocalizer.string("Purchase could not be verified.")
                }
            case .userCancelled:
                statusMessage = AppLocalizer.string("Purchase cancelled.")
            case .pending:
                statusMessage = AppLocalizer.string("Purchase is pending approval.")
            @unknown default:
                statusMessage = AppLocalizer.string("Purchase could not be completed.")
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateEntitlements()
            statusMessage = isProUnlocked
                ? AppLocalizer.string("Purchases restored.")
                : AppLocalizer.string("No previous purchases were found.")
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func updateEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.proMonthlyID {
                unlocked = true
            }
        }
        isProUnlocked = unlocked
        subscriptionState = unlocked ? .active : .inactive
    }

    func remainingFreeUses(for feature: PremiumFeature) -> Int {
        max(0, Self.freeUseLimit - usageCounts()[feature.rawValue, default: 0])
    }

    func consumeFreeUseIfNeeded(for feature: PremiumFeature) -> Bool {
        guard !isProUnlocked else { return true }

        var usage = usageCounts()
        let current = usage[feature.rawValue, default: 0]
        guard current < Self.freeUseLimit else { return false }

        usage[feature.rawValue] = current + 1
        saveUsageCounts(usage)
        objectWillChange.send()
        return true
    }

    func hasAccess(to feature: PremiumFeature) -> Bool {
        isProUnlocked || remainingFreeUses(for: feature) > 0
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
}
