import Foundation
import Combine

// MARK: - API Client Configuration

struct APIConfiguration {
    static let baseURL: String = {
        #if DEBUG
        return "http://localhost:8000/api/v1"
        #else
        return "https://nagagent.com/api/v1"
        #endif
    }()
    
    static let timeout: TimeInterval = 30.0
}

// MARK: - API Error Types

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int, String?)
    case rateLimited
    case maintenance
    case tokenExpired
    case refreshTokenInvalid
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response format"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .maintenance:
            return "Service under maintenance"
        case .tokenExpired:
            return "Authentication token expired"
        case .refreshTokenInvalid:
            return "Refresh token is invalid"
        }
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API Request Protocol

protocol APIRequest {
    associatedtype Response: Codable
    
    var endpoint: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
    var body: Data? { get }
    var requiresAuth: Bool { get }
    var retryCount: Int { get }
}

extension APIRequest {
    var headers: [String: String]? { nil }
    var parameters: [String: Any]? { nil }
    var body: Data? { nil }
    var requiresAuth: Bool { true }
    var retryCount: Int { 3 }
}

// MARK: - API Client

class APIClient: ObservableObject {
    static let shared = APIClient()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var tokenManager: TokenManager
    
    @Published var isOnline = true
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfiguration.timeout
        config.timeoutIntervalForResource = APIConfiguration.timeout * 2
        
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.tokenManager = TokenManager.shared
        
        // Configure date formatting
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        
        // Monitor network connectivity
        startNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    
    func request<T: APIRequest>(_ request: T) -> AnyPublisher<T.Response, APIError> {
        guard isOnline else {
            return Fail(error: APIError.networkError(URLError(.notConnectedToInternet)))
                .eraseToAnyPublisher()
        }
        
        return buildURLRequest(from: request)
            .flatMap { [weak self] urlRequest in
                self?.performRequest(urlRequest, retries: request.retryCount) ?? 
                Fail(error: APIError.invalidResponse).eraseToAnyPublisher()
            }
            .decode(type: T.Response.self, decoder: decoder)
            .mapError { error in
                if error is DecodingError {
                    return APIError.decodingError(error)
                }
                return error as? APIError ?? APIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func requestWithAuth<T: APIRequest>(_ request: T) -> AnyPublisher<T.Response, APIError> {
        return tokenManager.getValidAccessToken()
            .flatMap { [weak self] _ in
                self?.request(request) ?? 
                Fail(error: APIError.unauthorized).eraseToAnyPublisher()
            }
            .catch { [weak self] error -> AnyPublisher<T.Response, APIError> in
                // Handle token refresh if unauthorized
                if case .unauthorized = error {
                    return self?.refreshTokenAndRetry(request) ?? 
                           Fail(error: APIError.unauthorized).eraseToAnyPublisher()
                }
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func buildURLRequest<T: APIRequest>(from request: T) -> AnyPublisher<URLRequest, APIError> {
        guard let url = buildURL(endpoint: request.endpoint, parameters: request.parameters) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        // Set default headers
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        request.headers?.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add authentication if required
        if request.requiresAuth {
            return tokenManager.getValidAccessToken()
                .map { token in
                    urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    urlRequest.httpBody = request.body
                    return urlRequest
                }
                .mapError { _ in APIError.unauthorized }
                .eraseToAnyPublisher()
        } else {
            urlRequest.httpBody = request.body
            return Just(urlRequest)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
    }
    
    private func buildURL(endpoint: String, parameters: [String: Any]?) -> URL? {
        guard let baseURL = URL(string: APIConfiguration.baseURL) else { return nil }
        let url = baseURL.appendingPathComponent(endpoint)
        
        guard let parameters = parameters, !parameters.isEmpty else {
            return url
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = parameters.map { key, value in
            URLQueryItem(name: key, value: String(describing: value))
        }
        
        return components?.url
    }
    
    private func performRequest(_ request: URLRequest, retries: Int) -> AnyPublisher<Data, APIError> {
        return session.dataTaskPublisher(for: request)
            .tryMap { [weak self] data, response in
                try self?.handleResponse(data: data, response: response) ?? data
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.networkError(error)
            }
            .retry(retries)
            .eraseToAnyPublisher()
    }
    
    private func handleResponse(data: Data, response: URLResponse) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 429:
            throw APIError.rateLimited
        case 503:
            throw APIError.maintenance
        case 400...499:
            let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = message?["message"] as? String
            throw APIError.serverError(httpResponse.statusCode, errorMessage)
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode, "Internal server error")
        default:
            throw APIError.serverError(httpResponse.statusCode, "Unknown error")
        }
    }
    
    private func refreshTokenAndRetry<T: APIRequest>(_ request: T) -> AnyPublisher<T.Response, APIError> {
        return tokenManager.refreshAccessToken()
            .flatMap { [weak self] _ in
                self?.request(request) ?? 
                Fail(error: APIError.unauthorized).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func startNetworkMonitoring() {
        // Simple network monitoring - can be enhanced with NWPathMonitor
        NotificationCenter.default.publisher(for: .NSURLSessionTaskDidCompleteWithError)
            .sink { [weak self] notification in
                if let error = notification.userInfo?["error"] as? URLError {
                    self?.isOnline = error.code != .notConnectedToInternet
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Convenience Methods

extension APIClient {
    func get<T: Codable>(_ endpoint: String, type: T.Type) -> AnyPublisher<T, APIError> {
        let request = BasicAPIRequest<T>(endpoint: endpoint, method: .GET)
        return self.request(request)
    }
    
    func post<T: Codable, U: Codable>(_ endpoint: String, body: U, responseType: T.Type) -> AnyPublisher<T, APIError> {
        do {
            let bodyData = try encoder.encode(body)
            let request = BasicAPIRequest<T>(endpoint: endpoint, method: .POST, body: bodyData)
            return self.request(request)
        } catch {
            return Fail(error: APIError.encodingError(error)).eraseToAnyPublisher()
        }
    }
    
    func put<T: Codable, U: Codable>(_ endpoint: String, body: U, responseType: T.Type) -> AnyPublisher<T, APIError> {
        do {
            let bodyData = try encoder.encode(body)
            let request = BasicAPIRequest<T>(endpoint: endpoint, method: .PUT, body: bodyData)
            return self.request(request)
        } catch {
            return Fail(error: APIError.encodingError(error)).eraseToAnyPublisher()
        }
    }
    
    func delete<T: Codable>(_ endpoint: String, responseType: T.Type) -> AnyPublisher<T, APIError> {
        let request = BasicAPIRequest<T>(endpoint: endpoint, method: .DELETE)
        return self.request(request)
    }
}

// MARK: - Basic API Request Implementation

private struct BasicAPIRequest<T: Codable>: APIRequest {
    typealias Response = T
    
    let endpoint: String
    let method: HTTPMethod
    let body: Data?
    let requiresAuth: Bool
    
    init(endpoint: String, method: HTTPMethod, body: Data? = nil, requiresAuth: Bool = true) {
        self.endpoint = endpoint
        self.method = method
        self.body = body
        self.requiresAuth = requiresAuth
    }
}