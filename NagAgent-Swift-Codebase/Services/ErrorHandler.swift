import Foundation
import Combine
import SwiftUI

// MARK: - Error Handling Service

class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var isShowingError = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Auto-dismiss errors after delay
        $currentError
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.isShowingError = true
                
                // Auto-dismiss non-critical errors
                if !error.isPersistent {
                    DispatchQueue.main.asyncAfter(deadline: .now() + error.dismissDelay) {
                        self?.dismissError()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func handle(_ error: Error) {
        let appError = AppError.from(error)
        
        DispatchQueue.main.async {
            self.currentError = appError
        }
        
        // Log error for debugging
        logError(appError)
        
        // Send analytics if needed
        reportError(appError)
    }
    
    func dismissError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.isShowingError = false
        }
    }
    
    private func logError(_ error: AppError) {
        #if DEBUG
        print("🚨 AppError: \(error.title)")
        print("   Message: \(error.message)")
        print("   Category: \(error.category)")
        if let underlying = error.underlyingError {
            print("   Underlying: \(underlying)")
        }
        #endif
    }
    
    private func reportError(_ error: AppError) {
        // TODO: Integrate with analytics service
        // FirebaseCrashlytics.crashlytics().record(error: error)
    }
}

// MARK: - App Error Model

struct AppError: Error, Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let category: ErrorCategory
    let severity: ErrorSeverity
    let recoveryActions: [RecoveryAction]
    let underlyingError: Error?
    
    var isPersistent: Bool {
        severity == .critical
    }
    
    var dismissDelay: TimeInterval {
        switch severity {
        case .info: return 3.0
        case .warning: return 5.0
        case .error: return 7.0
        case .critical: return 0 // Manual dismiss only
        }
    }
    
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        if let apiError = error as? APIError {
            return fromAPIError(apiError)
        }
        
        if let urlError = error as? URLError {
            return fromURLError(urlError)
        }
        
        return AppError(
            title: "Unexpected Error",
            message: error.localizedDescription,
            category: .unknown,
            severity: .error,
            recoveryActions: [.dismiss],
            underlyingError: error
        )
    }
    
    private static func fromAPIError(_ apiError: APIError) -> AppError {
        switch apiError {
        case .networkError(let error):
            if let urlError = error as? URLError {
                return fromURLError(urlError)
            }
            return AppError(
                title: "Network Error",
                message: "Please check your internet connection",
                category: .network,
                severity: .error,
                recoveryActions: [.retry, .dismiss],
                underlyingError: error
            )
            
        case .unauthorized:
            return AppError(
                title: "Authentication Required",
                message: "Please log in again",
                category: .authentication,
                severity: .error,
                recoveryActions: [.login, .dismiss],
                underlyingError: apiError
            )
            
        case .forbidden:
            return AppError(
                title: "Access Denied",
                message: "You don't have permission to access this resource",
                category: .authorization,
                severity: .error,
                recoveryActions: [.dismiss],
                underlyingError: apiError
            )
            
        case .rateLimited:
            return AppError(
                title: "Too Many Requests",
                message: "Please wait a moment before trying again",
                category: .rateLimit,
                severity: .warning,
                recoveryActions: [.wait, .dismiss],
                underlyingError: apiError
            )
            
        case .serverError(let code, let message):
            return AppError(
                title: "Server Error",
                message: message ?? "The server encountered an error (Code: \(code))",
                category: .server,
                severity: .error,
                recoveryActions: [.retry, .dismiss],
                underlyingError: apiError
            )
            
        case .maintenance:
            return AppError(
                title: "Service Maintenance",
                message: "The service is temporarily unavailable due to maintenance",
                category: .maintenance,
                severity: .warning,
                recoveryActions: [.wait, .dismiss],
                underlyingError: apiError
            )
            
        case .decodingError:
            return AppError(
                title: "Data Processing Error",
                message: "There was an issue processing the response from the server",
                category: .dataProcessing,
                severity: .error,
                recoveryActions: [.retry, .contact],
                underlyingError: apiError
            )
            
        default:
            return AppError(
                title: "API Error",
                message: apiError.localizedDescription,
                category: .api,
                severity: .error,
                recoveryActions: [.retry, .dismiss],
                underlyingError: apiError
            )
        }
    }
    
    private static func fromURLError(_ urlError: URLError) -> AppError {
        switch urlError.code {
        case .notConnectedToInternet:
            return AppError(
                title: "No Internet Connection",
                message: "Please check your internet connection and try again",
                category: .network,
                severity: .error,
                recoveryActions: [.retry, .settings],
                underlyingError: urlError
            )
            
        case .timedOut:
            return AppError(
                title: "Request Timeout",
                message: "The request took too long to complete. Please try again",
                category: .network,
                severity: .error,
                recoveryActions: [.retry, .dismiss],
                underlyingError: urlError
            )
            
        case .cannotFindHost, .cannotConnectToHost:
            return AppError(
                title: "Connection Failed",
                message: "Unable to connect to the server. Please try again later",
                category: .network,
                severity: .error,
                recoveryActions: [.retry, .dismiss],
                underlyingError: urlError
            )
            
        default:
            return AppError(
                title: "Network Error",
                message: urlError.localizedDescription,
                category: .network,
                severity: .error,
                recoveryActions: [.retry, .dismiss],
                underlyingError: urlError
            )
        }
    }
}

// MARK: - Error Categories and Severity

enum ErrorCategory: String, CaseIterable {
    case network = "network"
    case authentication = "authentication"
    case authorization = "authorization"
    case api = "api"
    case server = "server"
    case dataProcessing = "data_processing"
    case validation = "validation"
    case storage = "storage"
    case payment = "payment"
    case notification = "notification"
    case rateLimit = "rate_limit"
    case maintenance = "maintenance"
    case unknown = "unknown"
}

enum ErrorSeverity: String, CaseIterable {
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
}

enum RecoveryAction: String, CaseIterable {
    case retry = "retry"
    case dismiss = "dismiss"
    case login = "login"
    case settings = "settings"
    case contact = "contact"
    case wait = "wait"
    case update = "update"
    
    var title: String {
        switch self {
        case .retry: return "Retry"
        case .dismiss: return "Dismiss"
        case .login: return "Login"
        case .settings: return "Settings"
        case .contact: return "Contact Support"
        case .wait: return "Wait"
        case .update: return "Update App"
        }
    }
}

// MARK: - Retry Logic Service

class RetryService {
    static let shared = RetryService()
    
    private init() {}
    
    func retry<T>(
        operation: @escaping () -> AnyPublisher<T, Error>,
        maxRetries: Int = 3,
        delay: TimeInterval = 1.0,
        multiplier: Double = 2.0,
        shouldRetry: @escaping (Error) -> Bool = { _ in true }
    ) -> AnyPublisher<T, Error> {
        
        return operation()
            .catch { error -> AnyPublisher<T, Error> in
                guard shouldRetry(error), maxRetries > 0 else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                
                return Just(())
                    .delay(for: .seconds(delay), scheduler: DispatchQueue.global())
                    .flatMap { _ in
                        self.retry(
                            operation: operation,
                            maxRetries: maxRetries - 1,
                            delay: delay * multiplier,
                            multiplier: multiplier,
                            shouldRetry: shouldRetry
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func shouldRetryAPIError(_ error: Error) -> Bool {
        guard let apiError = error as? APIError else { return false }
        
        switch apiError {
        case .networkError, .serverError(let code, _) where code >= 500, .rateLimited:
            return true
        case .unauthorized, .forbidden, .notFound, .decodingError, .encodingError:
            return false
        default:
            return false
        }
    }
    
    func exponentialBackoff(attempt: Int, baseDelay: TimeInterval = 1.0) -> TimeInterval {
        let delay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.1) * delay
        return delay + jitter
    }
}

// MARK: - Error Alert View

struct ErrorAlertView: View {
    @ObservedObject var errorHandler = ErrorHandler.shared
    
    var body: some View {
        EmptyView()
            .alert(
                errorHandler.currentError?.title ?? "Error",
                isPresented: $errorHandler.isShowingError,
                presenting: errorHandler.currentError
            ) { error in
                ForEach(error.recoveryActions, id: \.self) { action in
                    Button(action.title) {
                        handleRecoveryAction(action)
                    }
                }
            } message: { error in
                Text(error.message)
            }
    }
    
    private func handleRecoveryAction(_ action: RecoveryAction) {
        switch action {
        case .dismiss:
            errorHandler.dismissError()
        case .retry:
            // This should be handled by the calling view
            errorHandler.dismissError()
        case .login:
            AuthenticationStateManager.shared.logout()
            errorHandler.dismissError()
        case .settings:
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
            errorHandler.dismissError()
        case .contact:
            // Open support email or contact form
            if let emailUrl = URL(string: "mailto:support@nagagent.com") {
                UIApplication.shared.open(emailUrl)
            }
            errorHandler.dismissError()
        case .wait:
            errorHandler.dismissError()
        case .update:
            // Open App Store for update
            errorHandler.dismissError()
        }
    }
}

// MARK: - Publisher Extensions for Error Handling

extension Publisher {
    func handleErrors() -> AnyPublisher<Output, Never> {
        return self
            .catch { error -> AnyPublisher<Output, Never> in
                ErrorHandler.shared.handle(error)
                return Empty().eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func retryOnFailure(
        maxRetries: Int = 3,
        delay: TimeInterval = 1.0,
        shouldRetry: @escaping (Failure) -> Bool = { _ in true }
    ) -> AnyPublisher<Output, Failure> {
        return RetryService.shared.retry(
            operation: { self.eraseToAnyPublisher() },
            maxRetries: maxRetries,
            delay: delay,
            shouldRetry: { shouldRetry($0 as! Failure) }
        )
        .mapError { $0 as! Failure }
        .eraseToAnyPublisher()
    }
}

// MARK: - Custom Error Types

extension AppError {
    static let noInternetConnection = AppError(
        title: "No Internet Connection",
        message: "Please check your internet connection and try again",
        category: .network,
        severity: .error,
        recoveryActions: [.retry, .settings],
        underlyingError: nil
    )
    
    static let subscriptionExpired = AppError(
        title: "Subscription Expired",
        message: "Your subscription has expired. Please renew to continue using premium features",
        category: .payment,
        severity: .warning,
        recoveryActions: [.update, .dismiss],
        underlyingError: nil
    )
    
    static let pushNotificationsDenied = AppError(
        title: "Notifications Disabled",
        message: "Enable notifications in Settings to receive roasts and reminders",
        category: .notification,
        severity: .warning,
        recoveryActions: [.settings, .dismiss],
        underlyingError: nil
    )
    
    static func validationError(_ message: String) -> AppError {
        return AppError(
            title: "Validation Error",
            message: message,
            category: .validation,
            severity: .warning,
            recoveryActions: [.dismiss],
            underlyingError: nil
        )
    }
    
    static func storageError(_ message: String) -> AppError {
        return AppError(
            title: "Storage Error",
            message: message,
            category: .storage,
            severity: .error,
            recoveryActions: [.retry, .contact],
            underlyingError: nil
        )
    }
}