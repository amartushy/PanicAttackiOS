import StoreKit
import Combine
import Firebase
import FirebaseAuth

class StoreManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    var productID = "monthly_premium"
    var premiumProduct: SKProduct?
    @Published var productPrice: String? = nil

    override init() {
        super.init()
        print("StoreManager initialized.")
        SKPaymentQueue.default().add(self)
        fetchProducts()
        
        if #available(iOS 15.0, *) {
            Task {
                await checkActiveSubscription()
            }
        } else {
            // Handle older iOS versions, possibly using server-side verification if needed
        }
    }
    
    func fetchProducts() {
        print("Fetching products...")
        let request = SKProductsRequest(productIdentifiers: [productID])
        request.delegate = self
        request.start()
    }
    
    private func formatPrice(product: SKProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? ""
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            // Check if the fetched products list is not empty
            DispatchQueue.main.async {
                if let product = response.products.first(where: { $0.productIdentifier == self.productID }) {
                    self.premiumProduct = product
                    self.productPrice = self.formatPrice(product: product)
                } else {
                    print("No products found or product not matched.")
                }
            }
            
            // Check for invalid product identifiers
            if !response.invalidProductIdentifiers.isEmpty {
                print("Invalid product identifiers found:")
                for invalidIdentifier in response.invalidProductIdentifiers {
                    print(invalidIdentifier)
                }
            }
        }
    }
    
    func startSubscriptionProcess(completion: @escaping (Bool, String?) -> Void) {
        guard let product = premiumProduct else {
            print("Attempted to start subscription process, but product is nil.")
            completion(false, "Product not found. Please try again later.")
            return
        }
        
        print("Starting subscription process for product: \(product.productIdentifier)")
        buyProduct(product)
    }
    
    func buyProduct(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        print("Added payment for product: \(product.productIdentifier) to the payment queue.")
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            print("Transaction state updated: \(transaction.transactionState.rawValue)")
            switch transaction.transactionState {
            case .purchased, .restored:
                print("Transaction successful for product ID: \(String(describing: transaction.payment.productIdentifier)).")
                DispatchQueue.main.async {
                    self.updateSubscriptionStatus(isSubscribed: true)
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                print("Transaction failed for product ID: \(String(describing: transaction.payment.productIdentifier)). Error: \(String(describing: transaction.error))")
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                print("Transaction in an unhandled state: \(transaction.transactionState.rawValue)")
            }
        }
    }
    
    func updateSubscriptionStatus(isSubscribed : Bool) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: User is not logged in")
            return
        }
        
        let userInfo = database.collection("users").document(userID)
        userInfo.updateData(["isUserSubscribed" : isSubscribed]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated subscription status to: \(isSubscribed)")
            }
        }
    }
    
    @available(iOS 15.0, *)
    func checkActiveSubscription() async {
        print("Checking for active subscription...")
        do {
            for try await transaction in Transaction.currentEntitlements {
                guard case .verified(let verifiedTransaction) = transaction else {
                    print("Transaction not verified or in an unexpected state.")
                    self.updateSubscriptionStatus(isSubscribed: false)
                    continue
                }
                
                if verifiedTransaction.productID == productID,
                   verifiedTransaction.revocationDate == nil,
                   let expiryDate = verifiedTransaction.expirationDate, expiryDate > Date() {
                    print("Active subscription found. Expiration : \(expiryDate)")
                    self.updateSubscriptionStatus(isSubscribed: true)

                    return
                }
            }
        }
        print("No active subscription found.")
        self.updateSubscriptionStatus(isSubscribed: false)

    }
}
