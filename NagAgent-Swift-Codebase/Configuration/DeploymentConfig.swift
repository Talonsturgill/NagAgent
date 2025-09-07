import Foundation

// MARK: - Deployment Configuration for App Store

struct DeploymentConfig {
    // TODO: Update this with your actual production URL after deploying backend
    static let productionAPIURL = "https://nagagent-backend.railway.app/api/v1"
    
    // App Store Configuration
    static let appBundleID = "com.talonsturgill.NagAgent"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    
    // RevenueCat Configuration (if using subscriptions)
    static let revenueCatAPIKey = "your_revenuecat_key_here"
    
    // Firebase Configuration (for push notifications)
    static let firebaseEnabled = false // Set to true when Firebase is configured
}

// Update APIConfiguration to use deployment config
extension APIConfiguration {
    static var deploymentURL: String {
        #if DEBUG
        return "http://localhost:8000/api/v1"
        #else
        return DeploymentConfig.productionAPIURL
        #endif
    }
}