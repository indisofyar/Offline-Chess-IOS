//
//  PurchaseManager.swift
//  Offline Chess
//

import Foundation
import StoreKit

/// Drives the app's single one-time, non-consumable "unlock pro"
/// in-app purchase using StoreKit 2.
///
/// - note: The product below (``PurchaseManager/unlockProductID``) must
/// be created in App Store Connect before purchases will resolve;
/// until then ``loadProduct()`` simply won't find a product and the
/// paywall shows its "unavailable" state.
@MainActor
@Observable
final class PurchaseManager {

    /// The bundle ID-scoped product identifier for the one-time unlock.
    static let unlockProductID = "indi.OfflineChess.unlockPro"

    private(set) var product: Product?
    private(set) var isLoadingProduct = false
    var isPremium = false
    var lastErrorMessage: String?

    private var transactionListenerTask: Task<Void, Never>?

    init() {
        transactionListenerTask = Task { [weak self] in
            await self?.listenForTransactionUpdates()
        }

        Task { [weak self] in
            await self?.loadProduct()
            await self?.refreshEntitlements()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    /// A friendly, localized price string to show on the paywall, with
    /// a sensible fallback before the real StoreKit product has loaded.
    var priceText: String {
        product?.displayPrice ?? "£6.00"
    }

    func loadProduct() async {
        isLoadingProduct = true
        defer { isLoadingProduct = false }

        do {
            let products = try await Product.products(for: [Self.unlockProductID])
            product = products.first
        } catch {
            lastErrorMessage = "Couldn't load the store item: \(error.localizedDescription)"
        }
    }

    func purchase() async {
        guard let product else { return }

        do {
            let result = try await product.purchase()

            switch result {
            case let .success(verification):
                switch verification {
                case let .verified(transaction):
                    isPremium = true
                    await transaction.finish()
                case .unverified:
                    lastErrorMessage = "Your purchase could not be verified. Please try again."
                }
            case .userCancelled:
                break
            case .pending:
                lastErrorMessage = "Your purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastErrorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        var unlocked = false

        for await result in Transaction.currentEntitlements {
            if case let .verified(transaction) = result, transaction.productID == Self.unlockProductID {
                unlocked = true
            }
        }

        isPremium = unlocked
    }

    private func listenForTransactionUpdates() async {
        for await update in Transaction.updates {
            guard case let .verified(transaction) = update else { continue }

            if transaction.productID == Self.unlockProductID {
                isPremium = true
            }

            await transaction.finish()
        }
    }
}
