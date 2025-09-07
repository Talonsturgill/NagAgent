import Foundation
import Combine
import SwiftUI

// MARK: - Subscription ViewModel

@MainActor
class SubscriptionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSubscription: Subscription?
    @Published var availableOfferings: [Offering] = []
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var isRestoring = false
    @Published var errorMessage: String?
    @Published var showPaywall = false
    
    // Subscription status
    @Published var isPremium = false
    @Published var subscriptionStatus: SubscriptionStatus = .free
    @Published var expirationDate: Date?
    @Published var autoRenewStatus: Bool = false
    
    // Feature access
    @Published var remainingRoasts = 5
    @Published var maxDailyGoals = 3
    @Published var canAccessAnalytics = false
    @Published var canCustomizePersonality = false
    
    // MARK: - Private Properties
    private let revenueCatService = RevenueCatService.shared
    private let apiClient = APIClient.shared
    private let errorHandler = ErrorHandler.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupRevenueCat()
        observeSubscriptionChanges()
        loadSubscriptionStatus()
    }
    
    // MARK: - Public Methods
    
    func loadSubscriptionStatus() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchRevenueCatStatus()
            }
            
            group.addTask {
                await self.fetchBackendSubscriptionInfo()
            }
            
            group.addTask {
                await self.loadAvailableOfferings()
            }
        }
        
        updateFeatureAccess()
        isLoading = false
    }
    
    func loadAvailableOfferings() async {
        do {
            availableOfferings = try await revenueCatService.getOfferings()
        } catch {
            handleError(error)
        }
    }
    
    func purchaseSubscription(_ offering: Offering) async -> Bool {
        guard !isPurchasing else { return false }
        
        isPurchasing = true
        errorMessage = nil
        
        do {
            let purchaseResult = try await revenueCatService.purchase(offering)
            
            if purchaseResult.success {
                // Update local status
                await fetchRevenueCatStatus()
                await syncWithBackend(purchaseResult.customerInfo)
                
                isPurchasing = false
                return true
            } else {
                isPurchasing = false
                return false
            }
            
        } catch {
            handleError(error)
            isPurchasing = false
            return false
        }
    }
    
    func restorePurchases() async -> Bool {
        guard !isRestoring else { return false }
        
        isRestoring = true
        errorMessage = nil
        
        do {
            let customerInfo = try await revenueCatService.restorePurchases()
            await syncWithBackend(customerInfo)
            await fetchRevenueCatStatus()
            
            isRestoring = false
            
            // Show success message if premium was restored
            if isPremium {
                // Could show a success alert here
                return true
            } else {
                errorMessage = "No active subscriptions found to restore"
                return false
            }
            
        } catch {
            handleError(error)
            isRestoring = false
            return false
        }
    }
    
    func showPaywallIfNeeded() {
        if !isPremium {
            showPaywall = true
        }
    }
    
    func checkFeatureAccess(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .unlimitedRoasts:
            return isPremium
        case .advancedAnalytics:
            return isPremium && canAccessAnalytics
        case .customPersonalities:
            return isPremium && canCustomizePersonality
        case .unlimitedGoals:
            return isPremium
        case .prioritySupport:
            return isPremium
        case .exportReports:
            return isPremium
        case .darkMode:
            return true // Free feature
        case .basicRoasts:
            return true // Free feature (with limits)
        }
    }
    
    func getRemainingTrialDays() -> Int? {
        guard let expirationDate = expirationDate,
              subscriptionStatus == .trial else { return nil }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
        return max(0, components.day ?? 0)
    }
    
    func cancelSubscription() async {
        // RevenueCat doesn't handle cancellation directly - redirect to App Store
        await openSubscriptionManagement()
    }
    
    func openSubscriptionManagement() async {
        if let url = await revenueCatService.getManagementURL() {
            await UIApplication.shared.open(url)
        }
    }
    
    func trackFeatureUsage(_ feature: PremiumFeature) {
        // Track feature usage for analytics
        Task {
            await logFeatureUsage(feature)
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func setupRevenueCat() {
        Task {
            await revenueCatService.configure()
        }
    }
    
    private func observeSubscriptionChanges() {
        revenueCatService.customerInfoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] customerInfo in
                self?.updateSubscriptionStatus(from: customerInfo)
            }
            .store(in: &cancellables)
    }
    
    private func fetchRevenueCatStatus() async {
        do {
            let customerInfo = try await revenueCatService.getCustomerInfo()
            updateSubscriptionStatus(from: customerInfo)
        } catch {
            handleError(error)
        }
    }
    
    private func fetchBackendSubscriptionInfo() async {
        do {
            let subscriptionInfo: BackendSubscriptionInfo = try await performRequest(
                endpoint: "/subscription/status",
                method: .GET
            )
            
            updateFeatureLimits(from: subscriptionInfo)
            
        } catch {
            handleError(error)
        }
    }
    
    private func syncWithBackend(_ customerInfo: CustomerInfo) async {
        let syncRequest = SubscriptionSyncRequest(
            revenueCatUserId: customerInfo.originalAppUserId,
            entitlements: customerInfo.entitlements.active.mapValues { entitlement in
                EntitlementInfo(
                    identifier: entitlement.identifier,
                    isActive: entitlement.isActive,
                    willRenew: entitlement.willRenew,
                    periodType: entitlement.periodType.rawValue,
                    productIdentifier: entitlement.productIdentifier,
                    purchaseDate: entitlement.originalPurchaseDate,
                    expirationDate: entitlement.expirationDate
                )
            }
        )
        
        do {
            let _: MessageResponse = try await performRequest(
                endpoint: "/subscription/sync",
                method: .POST,
                body: syncRequest
            )
        } catch {
            print("Failed to sync subscription with backend: \(error)")
        }
    }
    
    private func updateSubscriptionStatus(from customerInfo: CustomerInfo) {
        let premiumEntitlement = customerInfo.entitlements["premium"]
        
        isPremium = premiumEntitlement?.isActive == true
        autoRenewStatus = premiumEntitlement?.willRenew == true
        expirationDate = premiumEntitlement?.expirationDate
        
        // Determine subscription status
        if let entitlement = premiumEntitlement {
            if entitlement.isActive {
                subscriptionStatus = entitlement.periodType == .trial ? .trial : .premium
            } else {
                subscriptionStatus = .expired
            }
        } else {
            subscriptionStatus = .free
        }
        
        updateFeatureAccess()
    }
    
    private func updateFeatureLimits(from info: BackendSubscriptionInfo) {
        remainingRoasts = info.remainingRoasts
        maxDailyGoals = info.maxDailyGoals
        canAccessAnalytics = info.canAccessAnalytics
        canCustomizePersonality = info.canCustomizePersonality
    }
    
    private func updateFeatureAccess() {
        canAccessAnalytics = isPremium
        canCustomizePersonality = isPremium
        maxDailyGoals = isPremium ? 100 : 3
        remainingRoasts = isPremium ? 1000 : remainingRoasts
    }
    
    private func logFeatureUsage(_ feature: PremiumFeature) async {
        let request = FeatureUsageRequest(
            feature: feature.rawValue,
            timestamp: Date(),
            hasAccess: checkFeatureAccess(feature)
        )
        
        do {
            let _: MessageResponse = try await performRequest(
                endpoint: "/analytics/feature-usage",
                method: .POST,
                body: request
            )
        } catch {
            // Don't show error for analytics
            print("Failed to log feature usage: \(error)")
        }
    }
    
    private func performRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: T? = nil
    ) async throws -> U {
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = SubscriptionAPIRequest<T, U>(
                endpoint: endpoint,
                method: method,
                body: body
            )
            
            apiClient.requestWithAuth(request)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { response in
                        continuation.resume(returning: response)
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private func performRequest<U: Codable>(
        endpoint: String,
        method: HTTPMethod
    ) async throws -> U {
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = SimpleSubscriptionAPIRequest<U>(
                endpoint: endpoint,
                method: method
            )
            
            apiClient.requestWithAuth(request)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { response in
                        continuation.resume(returning: response)
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private func handleError(_ error: Error) {
        if let subscriptionError = error as? SubscriptionError {
            switch subscriptionError {
            case .userCancelled:
                return // Don't show error for user cancellation
            case .paymentFailed:
                errorMessage = "Payment failed. Please check your payment method."
            case .productNotAvailable:
                errorMessage = "This subscription is not available right now."
            case .networkError:
                errorMessage = "Please check your internet connection."
            default:
                errorMessage = subscriptionError.localizedDescription
            }
        } else if let apiError = error as? APIError {
            switch apiError {
            case .networkError:
                errorMessage = "Please check your internet connection"
            case .unauthorized:
                errorMessage = "Session expired. Please log in again"
                AuthenticationStateManager.shared.logout()
            default:
                errorMessage = apiError.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
        
        errorHandler.handle(error)
    }
}

// MARK: - Supporting Types

enum SubscriptionStatus {
    case free
    case trial
    case premium
    case expired
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .trial: return "Trial"
        case .premium: return "Premium"
        case .expired: return "Expired"
        }
    }
    
    var color: Color {
        switch self {
        case .free: return .gray
        case .trial: return .blue
        case .premium: return .purple
        case .expired: return .red
        }
    }
}

enum PremiumFeature: String, CaseIterable {
    case unlimitedRoasts = "unlimited_roasts"
    case advancedAnalytics = "advanced_analytics"
    case customPersonalities = "custom_personalities"
    case unlimitedGoals = "unlimited_goals"
    case prioritySupport = "priority_support"
    case exportReports = "export_reports"
    case darkMode = "dark_mode"
    case basicRoasts = "basic_roasts"
    
    var displayName: String {
        switch self {
        case .unlimitedRoasts: return "Unlimited Roasts"
        case .advancedAnalytics: return "Advanced Analytics"
        case .customPersonalities: return "Custom Personalities"
        case .unlimitedGoals: return "Unlimited Goals"
        case .prioritySupport: return "Priority Support"
        case .exportReports: return "Export Reports"
        case .darkMode: return "Dark Mode"
        case .basicRoasts: return "Basic Roasts"
        }
    }
    
    var icon: String {
        switch self {
        case .unlimitedRoasts: return "infinity"
        case .advancedAnalytics: return "chart.bar.fill"
        case .customPersonalities: return "person.fill.badge.plus"
        case .unlimitedGoals: return "target"
        case .prioritySupport: return "headphones"
        case .exportReports: return "square.and.arrow.up"
        case .darkMode: return "moon.fill"
        case .basicRoasts: return "bubble.left"
        }
    }
}

// MARK: - API Models

private struct SubscriptionAPIRequest<T: Codable, U: Codable>: APIRequest {
    typealias Response = U
    
    let endpoint: String
    let method: HTTPMethod
    let body: Data?
    let requiresAuth = true
    
    init(endpoint: String, method: HTTPMethod, body: T?) {
        self.endpoint = endpoint
        self.method = method
        
        if let body = body {
            do {
                self.body = try JSONEncoder().encode(body)
            } catch {
                self.body = nil
                print("Failed to encode request body: \(error)")
            }
        } else {
            self.body = nil
        }
    }
}

private struct SimpleSubscriptionAPIRequest<U: Codable>: APIRequest {
    typealias Response = U
    
    let endpoint: String
    let method: HTTPMethod
    let body: Data? = nil
    let requiresAuth = true
}

struct BackendSubscriptionInfo: Codable {
    let subscriptionTier: String
    let isActive: Bool
    let expirationDate: Date?
    let remainingRoasts: Int
    let maxDailyGoals: Int
    let canAccessAnalytics: Bool
    let canCustomizePersonality: Bool
    
    enum CodingKeys: String, CodingKey {
        case subscriptionTier = "subscription_tier"
        case isActive = "is_active"
        case expirationDate = "expiration_date"
        case remainingRoasts = "remaining_roasts"
        case maxDailyGoals = "max_daily_goals"
        case canAccessAnalytics = "can_access_analytics"
        case canCustomizePersonality = "can_customize_personality"
    }
}

struct SubscriptionSyncRequest: Codable {
    let revenueCatUserId: String
    let entitlements: [String: EntitlementInfo]
    
    enum CodingKeys: String, CodingKey {
        case revenueCatUserId = "revenue_cat_user_id"
        case entitlements
    }
}

struct EntitlementInfo: Codable {
    let identifier: String
    let isActive: Bool
    let willRenew: Bool
    let periodType: String
    let productIdentifier: String
    let purchaseDate: Date
    let expirationDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case identifier
        case isActive = "is_active"
        case willRenew = "will_renew"
        case periodType = "period_type"
        case productIdentifier = "product_identifier"
        case purchaseDate = "purchase_date"
        case expirationDate = "expiration_date"
    }
}

struct FeatureUsageRequest: Codable {
    let feature: String
    let timestamp: Date
    let hasAccess: Bool
    
    enum CodingKeys: String, CodingKey {
        case feature, timestamp
        case hasAccess = "has_access"
    }
}

// MARK: - RevenueCat Service Protocol

protocol RevenueCatServiceProtocol {
    var customerInfoPublisher: AnyPublisher<CustomerInfo, Never> { get }
    
    func configure() async
    func getCustomerInfo() async throws -> CustomerInfo
    func getOfferings() async throws -> [Offering]
    func purchase(_ offering: Offering) async throws -> PurchaseResult
    func restorePurchases() async throws -> CustomerInfo
    func getManagementURL() async -> URL?
}

// MARK: - Mock Data Models (to be replaced with actual RevenueCat models)

struct CustomerInfo {
    let originalAppUserId: String
    let entitlements: Entitlements
}

struct Entitlements {
    let active: [String: Entitlement]
}

struct Entitlement {
    let identifier: String
    let isActive: Bool
    let willRenew: Bool
    let periodType: PeriodType
    let productIdentifier: String
    let originalPurchaseDate: Date
    let expirationDate: Date?
}

enum PeriodType: String {
    case normal = "normal"
    case trial = "trial"
    case intro = "intro"
}

struct Offering: Identifiable {
    let id: String
    let identifier: String
    let serverDescription: String
    let packages: [Package]
}

struct Package: Identifiable {
    let id: String
    let identifier: String
    let packageType: PackageType
    let product: Product
}

enum PackageType: String {
    case monthly = "monthly"
    case annual = "annual"
    case weekly = "weekly"
    case custom = "custom"
}

struct Product {
    let identifier: String
    let displayName: String
    let displayPrice: String
    let price: Decimal
    let currencyCode: String
    let subscriptionPeriod: SubscriptionPeriod?
}

struct SubscriptionPeriod {
    let unit: PeriodUnit
    let value: Int
}

enum PeriodUnit {
    case day
    case week
    case month
    case year
}

struct PurchaseResult {
    let success: Bool
    let customerInfo: CustomerInfo
    let userCancelled: Bool
}

enum SubscriptionError: Error, LocalizedError {
    case userCancelled
    case paymentFailed
    case productNotAvailable
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Purchase was cancelled"
        case .paymentFailed:
            return "Payment failed"
        case .productNotAvailable:
            return "Product not available"
        case .networkError:
            return "Network error"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

// MARK: - Mock RevenueCat Service (to be replaced with actual implementation)

class RevenueCatService: RevenueCatServiceProtocol {
    static let shared = RevenueCatService()
    
    private let customerInfoSubject = PassthroughSubject<CustomerInfo, Never>()
    
    var customerInfoPublisher: AnyPublisher<CustomerInfo, Never> {
        customerInfoSubject.eraseToAnyPublisher()
    }
    
    func configure() async {
        // Configure RevenueCat SDK
        // RevenueCat.configure(withAPIKey: "your_api_key")
    }
    
    func getCustomerInfo() async throws -> CustomerInfo {
        // Return mock data for now
        return CustomerInfo(
            originalAppUserId: "user123",
            entitlements: Entitlements(active: [:])
        )
    }
    
    func getOfferings() async throws -> [Offering] {
        // Return mock data for now
        return []
    }
    
    func purchase(_ offering: Offering) async throws -> PurchaseResult {
        // Mock purchase
        return PurchaseResult(
            success: true,
            customerInfo: try await getCustomerInfo(),
            userCancelled: false
        )
    }
    
    func restorePurchases() async throws -> CustomerInfo {
        return try await getCustomerInfo()
    }
    
    func getManagementURL() async -> URL? {
        return URL(string: "https://apps.apple.com/account/subscriptions")
    }
}