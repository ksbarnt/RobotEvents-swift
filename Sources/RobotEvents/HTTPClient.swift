// HTTPClient.swift
// Low-level networking: URL building, authentication, retry on 429.

import Foundation

// MARK: - Errors

/// Errors thrown by the RobotEvents client.
public enum RobotEventsError: Error, LocalizedError, Sendable {
    /// The server returned a non-2xx status code.
    case httpError(statusCode: Int, message: String?)
    /// The response body could not be decoded.
    case decodingError(underlying: Error)
    /// A URL could not be constructed from the given components.
    case invalidURL
    /// No API key was provided.
    case missingAPIKey

    public var errorDescription: String? {
        switch self {
        case .httpError(let code, let msg):
            return "HTTP \(code): \(msg ?? "Unknown error")"
        case .decodingError(let err):
            return "Decoding failed: \(err.localizedDescription)"
        case .invalidURL:
            return "Could not construct a valid URL."
        case .missingAPIKey:
            return "A RobotEvents API key is required."
        }
    }
}

// MARK: - Internal HTTP client

final class HTTPClient: Sendable {

    private let apiKey: String
    private let session: URLSession
    private let baseURL = URL(string: "https://www.robotevents.com/api/v2")!

    static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let iso8601FormatterNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = iso8601Formatter.date(from: str) { return date }
            if let date = iso8601FormatterNoFraction.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot parse date: \(str)"
            )
        }
        return d
    }()

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: Request execution

    func get<T: Decodable & Sendable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        let url = try buildURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await execute(request: request)
    }

    // MARK: - Private helpers

    private func execute<T: Decodable & Sendable>(request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RobotEventsError.httpError(statusCode: -1, message: "Non-HTTP response")
        }

        // Handle rate limiting with automatic retry
        if http.statusCode == 429 {
            let delay = retryAfter(from: http) ?? 60
            try await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
            return try await execute(request: request)
        }

        guard (200...299).contains(http.statusCode) else {
            let msg = (try? Self.decoder.decode(APIError.self, from: data))?.message
            throw RobotEventsError.httpError(statusCode: http.statusCode, message: msg)
        }

        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw RobotEventsError.decodingError(underlying: error)
        }
    }

    private func buildURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else { throw RobotEventsError.invalidURL }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw RobotEventsError.invalidURL }
        return url
    }

    private func retryAfter(from response: HTTPURLResponse) -> Int? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After"),
              let seconds = Int(value) else { return nil }
        return seconds
    }
}

// MARK: - Query item builders

extension HTTPClient {

    /// Append a repeated array parameter, e.g. `id[]=1&id[]=2`.
    static func arrayItems<T: CustomStringConvertible>(
        key: String,
        values: [T]?
    ) -> [URLQueryItem] {
        guard let values else { return [] }
        return values.map { URLQueryItem(name: key, value: "\($0)") }
    }

    /// Append a single optional parameter.
    static func item(key: String, value: (some CustomStringConvertible)?) -> [URLQueryItem] {
        guard let value else { return [] }
        return [URLQueryItem(name: key, value: "\(value)")]
    }

    /// Format a Date as RFC 3339 for query parameters.
    static func format(date: Date?) -> String? {
        guard let date else { return nil }
        return iso8601Formatter.string(from: date)
    }

    /// Pagination items.
    static func pageItems(page: Int, perPage: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
        ]
    }
}
