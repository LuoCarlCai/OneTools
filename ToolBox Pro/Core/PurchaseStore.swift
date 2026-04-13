import Foundation
import Combine
import StoreKit

@MainActor
final class PurchaseStore: ObservableObject {
    static let removeAdsLifetimeID = "com.carl.toolboxpro.removeads.lifetime"

    @Published private(set) var isProUnlocked = false
    @Published private(set) var product: Product?
    @Published var statusMessage = ""

    init(loadStoreKit: Bool = true) {
        guard loadStoreKit else { return }
        Task {
            await refresh()
        }
    }

    func refresh() async {
        await requestProducts()
        await updateEntitlements()
    }

    func requestProducts() async {
        do {
            product = try await Product.products(for: [Self.removeAdsLifetimeID]).first
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
                    isProUnlocked = true
                    statusMessage = AppLocalizer.string("Pro unlocked successfully.")
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
            if transaction.productID == Self.removeAdsLifetimeID {
                unlocked = true
            }
        }
        isProUnlocked = unlocked
    }
}
