import Foundation

struct HTTPResponsePacket {
    let data: Data
    let response: HTTPURLResponse
}

actor HTTPLimiter {
    private let maxConcurrent: Int
    private var running = 0

    init(maxConcurrent: Int) {
        self.maxConcurrent = max(1, maxConcurrent)
    }

    func acquire() async {
        while running >= maxConcurrent {
            await Task.yield()
        }
        running += 1
    }

    func release() {
        running = max(0, running - 1)
    }
}

struct HTTPClient {
    private let session: URLSession
    private let limiter = HTTPLimiter(maxConcurrent: 6)

    init(configuration: URLSessionConfiguration = .default) {
        configuration.httpAdditionalHeaders = [
            "User-Agent": "KitsuneReader/1.0 (+https://pengin.dev)"
        ]
        configuration.waitsForConnectivity = true
#if os(iOS)
        configuration.multipathServiceType = .handover
#endif
        configuration.allowsExpensiveNetworkAccess = true
        configuration.httpMaximumConnectionsPerHost = 6
        session = URLSession(configuration: configuration)
    }

    func fetch(_ request: URLRequest) async throws -> HTTPResponsePacket {
        await limiter.acquire()
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            await limiter.release()
            return HTTPResponsePacket(data: data, response: http)
        } catch {
            await limiter.release()
            throw error
        }
    }

    func fetch(url: URL, headers: [String: String] = [:]) async throws -> HTTPResponsePacket {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        return try await fetch(request)
    }
}
