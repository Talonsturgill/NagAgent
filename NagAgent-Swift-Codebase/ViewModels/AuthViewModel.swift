import Foundation
import Combine
import SwiftUI

// MARK: - Authentication ViewModel

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var errorMessage: String?
    
    // Login form
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    
    // Register form
    @Published var registerEmail = ""
    @Published var registerPassword = ""
    @Published var registerConfirmPassword = ""
    @Published var registerName = ""
    @Published var selectedPersonality: PersonalityType = .sassy
    @Published var selectedTimezone = "America/New_York"
    
    // Form validation
    @Published var isLoginFormValid = false
    @Published var isRegisterFormValid = false
    
    // MARK: - Private Properties
    private let apiClient = APIClient.shared
    private let authStateManager = AuthenticationStateManager.shared
    private let errorHandler = ErrorHandler.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupValidation()
        observeAuthState()
    }
    
    // MARK: - Public Methods
    
    func login() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        let loginRequest = LoginRequest(
            email: loginEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            password: loginPassword
        )
        
        do {
            let response: LoginResponse = try await performRequest(
                endpoint: "/auth/login",
                method: .POST,
                body: loginRequest,
                requiresAuth: false
            )
            
            // Save tokens
            let tokenResponse = TokenResponse(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                tokenType: response.tokenType,
                expiresIn: response.expiresIn
            )
            
            TokenManager.shared.saveTokens(tokenResponse)
            
            // Fetch user profile
            await fetchUserProfile()
            
            // Clear form
            clearLoginForm()
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func register() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        let registerRequest = RegisterRequest(
            email: registerEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            password: registerPassword,
            name: registerName.trimmingCharacters(in: .whitespacesAndNewlines),
            personality: selectedPersonality.rawValue,
            timezone: selectedTimezone
        )
        
        do {
            let response: LoginResponse = try await performRequest(
                endpoint: "/auth/register",
                method: .POST,
                body: registerRequest,
                requiresAuth: false
            )
            
            // Save tokens
            let tokenResponse = TokenResponse(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                tokenType: response.tokenType,
                expiresIn: response.expiresIn
            )
            
            TokenManager.shared.saveTokens(tokenResponse)
            
            // Fetch user profile
            await fetchUserProfile()
            
            // Clear form
            clearRegisterForm()
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func logout() {
        isLoading = true
        
        Task {
            do {
                // Call logout endpoint to invalidate server-side session
                let _: LogoutResponse = try await performRequest(
                    endpoint: "/auth/logout",
                    method: .POST,
                    body: EmptyBody(),
                    requiresAuth: true
                )
            } catch {
                // Continue with local logout even if server call fails
                print("Server logout failed: \(error)")
            }
            
            // Clear local data
            authStateManager.logout()
            currentUser = nil
            isLoading = false
        }
    }
    
    func fetchUserProfile() async {
        do {
            let profile: UserProfile = try await performRequest(
                endpoint: "/auth/profile",
                method: .GET,
                requiresAuth: true
            )
            
            currentUser = profile
            authStateManager.setUser(profile)
            
        } catch {
            handleError(error)
        }
    }
    
    func updateProfile(_ updates: ProfileUpdateRequest) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedProfile: UserProfile = try await performRequest(
                endpoint: "/auth/profile",
                method: .PUT,
                body: updates,
                requiresAuth: true
            )
            
            currentUser = updatedProfile
            authStateManager.setUser(updatedProfile)
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func changePassword(_ request: ChangePasswordRequest) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let _: MessageResponse = try await performRequest(
                endpoint: "/auth/change-password",
                method: .POST,
                body: request,
                requiresAuth: true
            )
            
            // Password changed successfully
            errorMessage = nil
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func requestPasswordReset(email: String) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        let request = PasswordResetRequest(email: email)
        
        do {
            let _: MessageResponse = try await performRequest(
                endpoint: "/auth/reset-password",
                method: .POST,
                body: request,
                requiresAuth: false
            )
            
            // Reset request sent successfully
            errorMessage = nil
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func deleteAccount() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let _: MessageResponse = try await performRequest(
                endpoint: "/auth/delete-account",
                method: .DELETE,
                requiresAuth: true
            )
            
            // Account deleted, logout user
            authStateManager.logout()
            currentUser = nil
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func clearLoginForm() {
        loginEmail = ""
        loginPassword = ""
    }
    
    func clearRegisterForm() {
        registerEmail = ""
        registerPassword = ""
        registerConfirmPassword = ""
        registerName = ""
        selectedPersonality = .sassy
        selectedTimezone = "America/New_York"
    }
    
    // MARK: - Private Methods
    
    private func setupValidation() {
        // Login form validation
        Publishers.CombineLatest(
            $loginEmail.map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.isValidEmail },
            $loginPassword.map { $0.count >= 6 }
        )
        .map { $0 && $1 }
        .assign(to: \.isLoginFormValid, on: self)
        .store(in: &cancellables)
        
        // Register form validation
        Publishers.CombineLatest4(
            $registerEmail.map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.isValidEmail },
            $registerPassword.map { $0.count >= 6 },
            $registerConfirmPassword.combineLatest($registerPassword).map { $0 == $1 && !$0.isEmpty },
            $registerName.map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        )
        .map { $0 && $1 && $2 && $3 }
        .assign(to: \.isRegisterFormValid, on: self)
        .store(in: &cancellables)
    }
    
    private func observeAuthState() {
        authStateManager.$isAuthenticated
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
        
        authStateManager.$user
            .assign(to: \.currentUser, on: self)
            .store(in: &cancellables)
    }
    
    private func performRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: T? = nil,
        requiresAuth: Bool = true
    ) async throws -> U {
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = AuthAPIRequest<T, U>(
                endpoint: endpoint,
                method: method,
                body: body,
                requiresAuth: requiresAuth
            )
            
            let publisher = requiresAuth ? 
                apiClient.requestWithAuth(request) : 
                apiClient.request(request)
            
            publisher
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
        method: HTTPMethod,
        requiresAuth: Bool = true
    ) async throws -> U {
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = SimpleAuthAPIRequest<U>(
                endpoint: endpoint,
                method: method,
                requiresAuth: requiresAuth
            )
            
            let publisher = requiresAuth ? 
                apiClient.requestWithAuth(request) : 
                apiClient.request(request)
            
            publisher
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
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                errorMessage = "Invalid email or password"
            case .forbidden:
                errorMessage = "Account access denied"
            case .serverError(let code, let message):
                if code == 409 {
                    errorMessage = "An account with this email already exists"
                } else {
                    errorMessage = message ?? "Server error occurred"
                }
            case .networkError:
                errorMessage = "Please check your internet connection"
            case .rateLimited:
                errorMessage = "Too many attempts. Please try again later"
            default:
                errorMessage = error.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
        
        // Also send to global error handler
        errorHandler.handle(error)
    }
}

// MARK: - API Request Models

private struct AuthAPIRequest<T: Codable, U: Codable>: APIRequest {
    typealias Response = U
    
    let endpoint: String
    let method: HTTPMethod
    let requiresAuth: Bool
    let body: Data?
    
    init(endpoint: String, method: HTTPMethod, body: T?, requiresAuth: Bool) {
        self.endpoint = endpoint
        self.method = method
        self.requiresAuth = requiresAuth
        
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

private struct SimpleAuthAPIRequest<U: Codable>: APIRequest {
    typealias Response = U
    
    let endpoint: String
    let method: HTTPMethod
    let requiresAuth: Bool
    let body: Data? = nil
}

// MARK: - Request/Response Models

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
    let personality: String
    let timezone: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

struct ProfileUpdateRequest: Codable {
    let name: String?
    let personality: String?
    let timezone: String?
    let notificationTimes: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name, personality, timezone
        case notificationTimes = "notification_times"
    }
}

struct ChangePasswordRequest: Codable {
    let currentPassword: String
    let newPassword: String
    
    enum CodingKeys: String, CodingKey {
        case currentPassword = "current_password"
        case newPassword = "new_password"
    }
}

struct PasswordResetRequest: Codable {
    let email: String
}

struct MessageResponse: Codable {
    let message: String
}

struct LogoutResponse: Codable {
    let message: String
}

struct EmptyBody: Codable {}

// MARK: - String Extensions

private extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
}

// MARK: - Publishers Extensions

extension Publishers {
    static func CombineLatest4<A: Publisher, B: Publisher, C: Publisher, D: Publisher>(
        _ a: A, _ b: B, _ c: C, _ d: D
    ) -> AnyPublisher<(A.Output, B.Output, C.Output, D.Output), A.Failure>
    where A.Failure == B.Failure, B.Failure == C.Failure, C.Failure == D.Failure {
        return Publishers.CombineLatest(
            Publishers.CombineLatest3(a, b, c),
            d
        )
        .map { (abc, d) in
            (abc.0, abc.1, abc.2, d)
        }
        .eraseToAnyPublisher()
    }
}