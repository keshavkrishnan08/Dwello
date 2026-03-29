import StoreKit
import SwiftUI

@Observable
class SubscriptionManager {
    static let shared = SubscriptionManager()

    // Product IDs — must match App Store Connect and Configuration.storekit
    static let yearlyID = "com.dwillo.premium.yearly"
    static let monthlyID = "com.dwillo.premium.monthly"
    static let allProductIDs: Set<String> = [yearlyID, monthlyID]

    // State
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false

    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyID }
    }

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyID }
    }

    private var transactionListener: Task<Void, Error>?

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await updatePurchasedProducts() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    @MainActor
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: Self.allProductIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    @MainActor
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = checkVerified(verification)
            if let transaction = transaction {
                await transaction.finish()
                await updatePurchasedProducts()
                return true
            }
            return false

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    @MainActor
    func restore() async {
        try? await StoreKit.AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = self.checkVerified(result) {
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                }
            }
        }
    }

    // MARK: - Update Status

    @MainActor
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = checkVerified(result) {
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            }
        }

        purchasedProductIDs = purchased
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) -> T? {
        switch result {
        case .unverified:
            return nil
        case .verified(let safe):
            return safe
        }
    }
}
