import Foundation
import Security
import Combine

// MARK: - Token Models

struct TokenResponse: Codable {
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

struct RefreshTokenRequest: Codable {
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

// MARK: - Keychain Helper

class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    
    private let service = "com.nagagent.app"
    
    private enum Keys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let tokenExpiry = "token_expiry"
    }
    
    func save<T: Codable>(_ item: T, forKey key: String) -> Bool {
        do {
            let data = try JSONEncoder().encode(item)
            return save(data, forKey: key)
        } catch {
            print("Failed to encode item for key \(key): \(error)")
            return false
        }
    }
    
    func save(_ data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = load(forKey: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to decode item for key \(key): \(error)")
            return nil
        }
    }
    
    func load(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return item as? Data
    }
    
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    func deleteAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Token-specific methods
    
    func saveTokens(_ tokens: TokenResponse) -> Bool {
        let expiryDate = Date().addingTimeInterval(TimeInterval(tokens.expiresIn))
        
        let accessSuccess = save(tokens.accessToken, forKey: Keys.accessToken)
        let refreshSuccess = save(tokens.refreshToken, forKey: Keys.refreshToken)
        let expirySuccess = save(expiryDate, forKey: Keys.tokenExpiry)
        
        return accessSuccess && refreshSuccess && expirySuccess
    }
    
    func getAccessToken() -> String? {
        return load(String.self, forKey: Keys.accessToken)
    }
    
    func getRefreshToken() -> String? {
        return load(String.self, forKey: Keys.refreshToken)
    }
    
    func getTokenExpiry() -> Date? {
        return load(Date.self, forKey: Keys.tokenExpiry)
    }
    
    func clearTokens() {
        _ = delete(forKey: Keys.accessToken)
        _ = delete(forKey: Keys.refreshToken)
        _ = delete(forKey: Keys.tokenExpiry)
    }
    
    func isTokenExpired() -> Bool {
        guard let expiry = getTokenExpiry() else { return true }
        // Add 5 minute buffer
        return Date().addingTimeInterval(300) >= expiry
    }
}

// MARK: - Token Manager

class TokenManager: ObservableObject {
    static let shared = TokenManager()
    
    private let keychain = KeychainHelper.shared
    private let refreshLock = NSLock()
    private var isRefreshing = false
    private var refreshPublisher: AnyPublisher<String, APIError>?
    
    @Published var isAuthenticated = false
    
    private init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Public Methods
    
    func saveTokens(_ tokens: TokenResponse) {
        let success = keychain.saveTokens(tokens)
        if success {
            DispatchQueue.main.async {
                self.isAuthenticated = true
            }
        }
    }
    
    func getValidAccessToken() -> AnyPublisher<String, APIError> {
        guard let token = keychain.getAccessToken() else {
            return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
        }
        
        if keychain.isTokenExpired() {
            return refreshAccessToken()
        }
        
        return Just(token)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    func refreshAccessToken() -> AnyPublisher<String, APIError> {
        refreshLock.lock()
        defer { refreshLock.unlock() }
        
        // If already refreshing, return the existing publisher
        if isRefreshing, let publisher = refreshPublisher {
            return publisher
        }
        
        guard let refreshToken = keychain.getRefreshToken() else {
            logout()
            return Fail(error: APIError.refreshTokenInvalid).eraseToAnyPublisher()
        }
        
        isRefreshing = true
        
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        let publisher = performTokenRefresh(request)
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.refreshLock.lock()
                    self?.isRefreshing = false
                    self?.refreshPublisher = nil
                    self?.refreshLock.unlock()
                },
                receiveCancel: { [weak self] in
                    self?.refreshLock.lock()
                    self?.isRefreshing = false
                    self?.refreshPublisher = nil
                    self?.refreshLock.unlock()
                }
            )
            .share()
            .eraseToAnyPublisher()
        
        refreshPublisher = publisher
        return publisher
    }
    
    func logout() {
        keychain.clearTokens()
        DispatchQueue.main.async {
            self.isAuthenticated = false
        }
    }
    
    func isUserAuthenticated() -> Bool {
        guard let _ = keychain.getAccessToken(),
              let _ = keychain.getRefreshToken() else {
            return false
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func checkAuthenticationStatus() {
        isAuthenticated = isUserAuthenticated()
    }
    
    private func performTokenRefresh(_ request: RefreshTokenRequest) -> AnyPublisher<String, APIError> {
        guard let url = URL(string: "\(APIConfiguration.baseURL)/auth/refresh") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            return Fail(error: APIError.encodingError(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { [weak self] data, response -> TokenResponse in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    break
                case 401, 403:
                    self?.logout()
                    throw APIError.refreshTokenInvalid
                default:
                    throw APIError.serverError(httpResponse.statusCode, nil)
                }
                
                do {
                    return try JSONDecoder().decode(TokenResponse.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            }
            .handleEvents(receiveOutput: { [weak self] tokens in
                self?.saveTokens(tokens)
            })
            .map { $0.accessToken }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Authentication State Manager

@MainActor
class AuthenticationStateManager: ObservableObject {
    static let shared = AuthenticationStateManager()
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var user: UserProfile?
    
    private let tokenManager = TokenManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Observe token manager authentication state
        tokenManager.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
        
        // Check initial authentication status
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        isAuthenticated = tokenManager.isUserAuthenticated()
    }
    
    func logout() {
        user = nil
        tokenManager.logout()
    }
    
    func setUser(_ user: UserProfile) {
        self.user = user
    }
}

// MARK: - User Profile Model

struct UserProfile: Codable, Identifiable {
    let id: Int
    let email: String
    let name: String?
    let personality: String
    let timezone: String
    let notificationTimes: [String]
    let subscriptionTier: String
    let isActive: Bool
    let isVerified: Bool
    let createdAt: Date
    let lastActive: Date
    let phoneNumber: String?
    let goals: [Goal]
    let totalGoals: Int
    let totalCompletedTasks: Int
    let currentStreak: Int
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, personality, timezone
        case notificationTimes = "notification_times"
        case subscriptionTier = "subscription_tier"
        case isActive = "is_active"
        case isVerified = "is_verified"
        case createdAt = "created_at"
        case lastActive = "last_active"
        case phoneNumber = "phone_number"
        case goals
        case totalGoals = "total_goals"
        case totalCompletedTasks = "total_completed_tasks"
        case currentStreak = "current_streak"
    }
}

struct Goal: Codable, Identifiable {
    let id: Int
    let userId: Int
    let goalText: String
    let isRecurring: Bool
    let createdAt: Date
    let archivedAt: Date?
    let dailyTasks: [DailyTask]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case goalText = "goal_text"
        case isRecurring = "is_recurring"
        case createdAt = "created_at"
        case archivedAt = "archived_at"
        case dailyTasks = "daily_tasks"
    }
}

struct DailyTask: Codable, Identifiable {
    let id: Int
    let userId: Int
    let goalId: Int
    let date: Date
    let completed: Bool
    let excuseGiven: String?
    let completedAt: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case goalId = "goal_id"
        case date, completed
        case excuseGiven = "excuse_given"
        case completedAt = "completed_at"
        case createdAt = "created_at"
    }
}