import Foundation
import Combine
import SwiftUI
// import RevenueCat // Uncomment when adding RevenueCat package

// MARK: - RevenueCat Configuration Service

class RevenueCatConfiguration {
    static let shared = RevenueCatConfiguration()
    
    private init() {}
    
    // RevenueCat API Keys
    private let apiKey: String = {
        #if DEBUG
        return "appl_debug_key_here" // Replace with actual debug key
        #else
        return "appl_production_key_here" // Replace with actual production key
        #endif
    }()
    
    // Product Identifiers
    enum ProductIdentifiers {
        static let monthly = "com.nagagent.premium.monthly"
        static let annual = "com.nagagent.premium.annual"
        static let weekly = "com.nagagent.premium.weekly"
    }
    
    // Entitlement Identifiers
    enum EntitlementIdentifiers {
        static let premium = "premium"
    }
    
    func configure(userId: String? = nil) {
        // Configure RevenueCat
        // Purchases.logLevel = .debug
        // Purchases.configure(withAPIKey: apiKey, appUserID: userId)
        
        #if DEBUG
        // Enable debug logging in debug builds
        // Purchases.logLevel = .debug
        #endif
    }
}

// MARK: - Enhanced RevenueCat Service

class RevenueCatService: RevenueCatServiceProtocol, ObservableObject {
    static let shared = RevenueCatService()
    
    // MARK: - Published Properties
    @Published var customerInfo: CustomerInfo?
    @Published var offerings: [Offering] = []
    @Published var isConfigured = false
    
    // MARK: - Private Properties
    private let customerInfoSubject = CurrentValueSubject<CustomerInfo?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()
    
    var customerInfoPublisher: AnyPublisher<CustomerInfo, Never> {
        customerInfoSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    private init() {
        setupPurchasesDelegate()
    }
    
    // MARK: - Configuration
    
    func configure(userId: String? = nil) async {
        RevenueCatConfiguration.shared.configure(userId: userId)
        
        // Set up purchases delegate
        // Purchases.shared.delegate = self
        
        await loadInitialData()
        isConfigured = true
    }
    
    private func loadInitialData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.refreshCustomerInfo()
            }
            
            group.addTask {
                await self.loadOfferings()
            }
        }
    }
    
    private func setupPurchasesDelegate() {
        // Set up delegate to receive updates
        // This would be implemented when RevenueCat is actually integrated
    }
    
    // MARK: - Customer Info
    
    func getCustomerInfo() async throws -> CustomerInfo {
        if let cachedInfo = customerInfo {
            return cachedInfo
        }
        
        return try await refreshCustomerInfo()
    }
    
    @discardableResult
    func refreshCustomerInfo() async -> CustomerInfo {
        // Mock implementation - replace with actual RevenueCat calls
        let mockInfo = createMockCustomerInfo()
        
        await MainActor.run {
            self.customerInfo = mockInfo
            self.customerInfoSubject.send(mockInfo)
        }
        
        return mockInfo
    }
    
    // MARK: - Offerings
    
    func getOfferings() async throws -> [Offering] {
        if !offerings.isEmpty {
            return offerings
        }
        
        return await loadOfferings()
    }
    
    @discardableResult
    private func loadOfferings() async -> [Offering] {
        // Mock implementation - replace with actual RevenueCat calls
        let mockOfferings = createMockOfferings()
        
        await MainActor.run {
            self.offerings = mockOfferings
        }
        
        return mockOfferings
    }
    
    // MARK: - Purchasing
    
    func purchase(_ offering: Offering) async throws -> PurchaseResult {
        guard let package = offering.packages.first else {
            throw SubscriptionError.productNotAvailable
        }
        
        return try await purchase(package)
    }
    
    func purchase(_ package: Package) async throws -> PurchaseResult {
        do {
            // Mock purchase logic - replace with actual RevenueCat calls
            /*
            let result = try await Purchases.shared.purchase(package: package.rcPackage)
            
            let purchaseResult = PurchaseResult(
                success: !result.userCancelled,
                customerInfo: convertCustomerInfo(result.customerInfo),
                userCancelled: result.userCancelled
            )
            */
            
            // Mock successful purchase
            let mockResult = PurchaseResult(
                success: true,
                customerInfo: createMockPremiumCustomerInfo(),
                userCancelled: false
            )
            
            // Update local customer info
            await MainActor.run {
                self.customerInfo = mockResult.customerInfo
                self.customerInfoSubject.send(mockResult.customerInfo)
            }
            
            // Track purchase
            await trackPurchaseEvent(package: package)
            
            return mockResult
            
        } catch {
            throw convertError(error)
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws -> CustomerInfo {
        do {
            // Mock restore logic - replace with actual RevenueCat calls
            /*
            let customerInfo = try await Purchases.shared.restorePurchases()
            let convertedInfo = convertCustomerInfo(customerInfo)
            */
            
            // Mock restore
            let mockInfo = createMockPremiumCustomerInfo()
            
            await MainActor.run {
                self.customerInfo = mockInfo
                self.customerInfoSubject.send(mockInfo)
            }
            
            // Track restore event
            await trackRestoreEvent()
            
            return mockInfo
            
        } catch {
            throw convertError(error)
        }
    }
    
    // MARK: - Subscription Management
    
    func getManagementURL() async -> URL? {
        // Try to get RevenueCat management URL first
        // let managementURL = await Purchases.shared.getCustomerInfo().managementURL
        
        // Fallback to App Store subscription management
        return URL(string: "https://apps.apple.com/account/subscriptions")
    }
    
    func isEligibleForIntro(_ package: Package) async -> Bool {
        // Check if user is eligible for intro pricing
        // let result = await Purchases.shared.checkTrialOrIntroDiscountEligibility(productIdentifiers: [package.product.identifier])
        // return result[package.product.identifier]?.status == .eligible
        
        // Mock eligibility
        return !hasActivePremium()
    }
    
    func hasActivePremium() -> Bool {
        return customerInfo?.entitlements.active[RevenueCatConfiguration.EntitlementIdentifiers.premium]?.isActive == true
    }
    
    func getExpirationDate() -> Date? {
        return customerInfo?.entitlements.active[RevenueCatConfiguration.EntitlementIdentifiers.premium]?.expirationDate
    }
    
    // MARK: - Analytics & Tracking
    
    private func trackPurchaseEvent(package: Package) async {
        // Send purchase event to analytics
        let event = PurchaseEvent(
            productId: package.product.identifier,
            packageType: package.packageType.rawValue,
            price: package.product.price,
            currency: package.product.currencyCode
        )
        
        // Send to backend analytics
        // await AnalyticsService.shared.track("subscription_purchased", parameters: event)
    }
    
    private func trackRestoreEvent() async {
        // Send restore event to analytics
        // await AnalyticsService.shared.track("subscription_restored")
    }
    
    // MARK: - Error Handling
    
    private func convertError(_ error: Error) -> SubscriptionError {
        // Convert RevenueCat errors to our custom errors
        /*
        if let purchasesError = error as? PurchasesError {
            switch purchasesError.code {
            case .purchaseCancelledError:
                return .userCancelled
            case .paymentPendingError:
                return .paymentFailed
            case .productNotAvailableForPurchaseError:
                return .productNotAvailable
            case .networkError:
                return .networkError
            default:
                return .unknown
            }
        }
        */
        
        return .unknown
    }
    
    // MARK: - Mock Data Creation (Remove when integrating real RevenueCat)
    
    private func createMockCustomerInfo() -> CustomerInfo {
        return CustomerInfo(
            originalAppUserId: "mock_user_123",
            entitlements: Entitlements(active: [:])
        )
    }
    
    private func createMockPremiumCustomerInfo() -> CustomerInfo {
        let premiumEntitlement = Entitlement(
            identifier: RevenueCatConfiguration.EntitlementIdentifiers.premium,
            isActive: true,
            willRenew: true,
            periodType: .normal,
            productIdentifier: RevenueCatConfiguration.ProductIdentifiers.monthly,
            originalPurchaseDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())
        )
        
        return CustomerInfo(
            originalAppUserId: "mock_user_123",
            entitlements: Entitlements(active: [
                RevenueCatConfiguration.EntitlementIdentifiers.premium: premiumEntitlement
            ])
        )
    }
    
    private func createMockOfferings() -> [Offering] {
        let monthlyProduct = Product(
            identifier: RevenueCatConfiguration.ProductIdentifiers.monthly,
            displayName: "Premium Monthly",
            displayPrice: "$4.99",
            price: 4.99,
            currencyCode: "USD",
            subscriptionPeriod: SubscriptionPeriod(unit: .month, value: 1)
        )
        
        let annualProduct = Product(
            identifier: RevenueCatConfiguration.ProductIdentifiers.annual,
            displayName: "Premium Annual",
            displayPrice: "$39.99",
            price: 39.99,
            currencyCode: "USD",
            subscriptionPeriod: SubscriptionPeriod(unit: .year, value: 1)
        )
        
        let monthlyPackage = Package(
            id: "monthly",
            identifier: "$rc_monthly",
            packageType: .monthly,
            product: monthlyProduct
        )
        
        let annualPackage = Package(
            id: "annual",
            identifier: "$rc_annual",
            packageType: .annual,
            product: annualProduct
        )
        
        let offering = Offering(
            id: "default",
            identifier: "default",
            serverDescription: "Default Offering",
            packages: [monthlyPackage, annualPackage]
        )
        
        return [offering]
    }
}

// MARK: - Purchase Event Model

struct PurchaseEvent: Codable {
    let productId: String
    let packageType: String
    let price: Decimal
    let currency: String
    let timestamp = Date()
}

// MARK: - RevenueCat Delegate (When integrating actual RevenueCat)

/*
extension RevenueCatService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = convertCustomerInfo(customerInfo)
            self.customerInfoSubject.send(self.customerInfo!)
        }
    }
    
    func purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase startPurchase: @escaping StartPurchaseBlock) {
        // Handle promoted purchases
        startPurchase { (transaction, customerInfo, error, cancelled) in
            // Handle the purchase result
        }
    }
}
*/

// MARK: - Paywall Service

class PaywallService: ObservableObject {
    @Published var shouldShowPaywall = false
    @Published var paywallTrigger: PaywallTrigger?
    
    enum PaywallTrigger {
        case featureGate(PremiumFeature)
        case onboarding
        case trialExpired
        case usageLimit
    }
    
    func showPaywall(trigger: PaywallTrigger) {
        paywallTrigger = trigger
        shouldShowPaywall = true
    }
    
    func hidePaywall() {
        shouldShowPaywall = false
        paywallTrigger = nil
    }
    
    func checkAndShowPaywallIfNeeded(for feature: PremiumFeature) {
        let subscriptionVM = SubscriptionViewModel()
        if !subscriptionVM.checkFeatureAccess(feature) {
            showPaywall(trigger: .featureGate(feature))
        }
    }
}

// MARK: - Subscription Tier Configuration

struct SubscriptionTier {
    let identifier: String
    let displayName: String
    let description: String
    let features: [PremiumFeature]
    let monthlyPrice: Decimal
    let annualPrice: Decimal
    let trialDays: Int
    
    static let premium = SubscriptionTier(
        identifier: "premium",
        displayName: "NagAgent Premium",
        description: "Unlimited roasts, advanced analytics, and custom personalities",
        features: [
            .unlimitedRoasts,
            .advancedAnalytics,
            .customPersonalities,
            .unlimitedGoals,
            .prioritySupport,
            .exportReports
        ],
        monthlyPrice: 4.99,
        annualPrice: 39.99,
        trialDays: 7
    )
    
    var annualSavings: Int {
        let monthlyCost = monthlyPrice * 12
        let savings = monthlyCost - annualPrice
        return Int((savings / monthlyCost) * 100)
    }
}

// MARK: - Subscription State Manager

@MainActor
class SubscriptionStateManager: ObservableObject {
    static let shared = SubscriptionStateManager()
    
    @Published var isPremium = false
    @Published var subscriptionStatus: SubscriptionStatus = .free
    @Published var remainingTrialDays: Int?
    @Published var nextBillingDate: Date?
    
    private let revenueCatService = RevenueCatService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        observeSubscriptionChanges()
    }
    
    private func observeSubscriptionChanges() {
        revenueCatService.customerInfoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] customerInfo in
                self?.updateSubscriptionState(from: customerInfo)
            }
            .store(in: &cancellables)
    }
    
    private func updateSubscriptionState(from customerInfo: CustomerInfo) {
        let premiumEntitlement = customerInfo.entitlements.active[RevenueCatConfiguration.EntitlementIdentifiers.premium]
        
        isPremium = premiumEntitlement?.isActive == true
        
        if let entitlement = premiumEntitlement, entitlement.isActive {
            subscriptionStatus = entitlement.periodType == .trial ? .trial : .premium
            nextBillingDate = entitlement.expirationDate
            
            if entitlement.periodType == .trial,
               let expirationDate = entitlement.expirationDate {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
                remainingTrialDays = max(0, components.day ?? 0)
            } else {
                remainingTrialDays = nil
            }
        } else {
            subscriptionStatus = .free
            nextBillingDate = nil
            remainingTrialDays = nil
        }
    }
    
    func checkFeatureAccess(_ feature: PremiumFeature) -> FeatureAccessResult {
        switch feature {
        case .basicRoasts, .darkMode:
            return .allowed
        case .unlimitedRoasts, .advancedAnalytics, .customPersonalities, .unlimitedGoals, .prioritySupport, .exportReports:
            return isPremium ? .allowed : .requiresPremium
        }
    }
}

enum FeatureAccessResult {
    case allowed
    case requiresPremium
    case requiresUpgrade
}

// MARK: - Usage Tracking

class UsageTracker: ObservableObject {
    static let shared = UsageTracker()
    
    @Published var dailyRoastCount = 0
    @Published var goalCount = 0
    
    private let maxFreeRoasts = 5
    private let maxFreeGoals = 3
    
    private init() {
        loadDailyUsage()
    }
    
    func canUseFeature(_ feature: PremiumFeature) -> Bool {
        let subscriptionState = SubscriptionStateManager.shared
        
        if subscriptionState.isPremium {
            return true
        }
        
        switch feature {
        case .basicRoasts:
            return dailyRoastCount < maxFreeRoasts
        case .unlimitedGoals:
            return goalCount < maxFreeGoals
        default:
            return false
        }
    }
    
    func trackUsage(_ feature: PremiumFeature) {
        switch feature {
        case .basicRoasts, .unlimitedRoasts:
            dailyRoastCount += 1
        default:
            break
        }
        
        saveDailyUsage()
    }
    
    func resetDailyLimits() {
        dailyRoastCount = 0
        saveDailyUsage()
    }
    
    private func loadDailyUsage() {
        // Load from UserDefaults or Core Data
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        let lastResetDate = defaults.object(forKey: "lastUsageReset") as? Date ?? today
        
        if !Calendar.current.isDate(lastResetDate, inSameDayAs: today) {
            resetDailyLimits()
            defaults.set(today, forKey: "lastUsageReset")
        } else {
            dailyRoastCount = defaults.integer(forKey: "dailyRoastCount")
        }
        
        goalCount = defaults.integer(forKey: "goalCount")
    }
    
    private func saveDailyUsage() {
        let defaults = UserDefaults.standard
        defaults.set(dailyRoastCount, forKey: "dailyRoastCount")
        defaults.set(goalCount, forKey: "goalCount")
    }
}