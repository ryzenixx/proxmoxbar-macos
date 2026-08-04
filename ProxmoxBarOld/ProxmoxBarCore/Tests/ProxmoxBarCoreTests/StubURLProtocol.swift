import Foundation

struct StubResponse {
    let statusCode: Int
    let body: Data

    static func ok(_ body: Data) -> StubResponse { StubResponse(statusCode: 200, body: body) }

    static func ok(_ body: String) -> StubResponse { .ok(Data(body.utf8)) }

    static func status(_ code: Int, _ body: String = "") -> StubResponse {
        StubResponse(statusCode: code, body: Data(body.utf8))
    }
}

final class StubTransport: Sendable {
    private let key = UUID().uuidString

    let configuration: URLSessionConfiguration

    init(_ handler: @escaping @Sendable (URLRequest) throws -> StubResponse) {
        configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        configuration.httpAdditionalHeaders = [StubURLProtocol.keyHeader: key]
        StubURLProtocol.register(key: key, handler: handler)
    }

    var requests: [URLRequest] { StubURLProtocol.requests(for: key) }

    var lastRequest: URLRequest? { requests.last }

    var requestCount: Int { requests.count }
}

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    static let keyHeader = "X-ProxmoxBarCore-Stub"

    private struct Entry {
        let handler: @Sendable (URLRequest) throws -> StubResponse
        var requests: [URLRequest] = []
    }

    nonisolated(unsafe) private static var entries: [String: Entry] = [:]
    private static let lock = NSLock()

    static func register(key: String, handler: @escaping @Sendable (URLRequest) throws -> StubResponse) {
        lock.withLock { entries[key] = Entry(handler: handler) }
    }

    static func requests(for key: String) -> [URLRequest] {
        lock.withLock { entries[key]?.requests ?? [] }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.value(forHTTPHeaderField: keyHeader) != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let key = request.value(forHTTPHeaderField: Self.keyHeader) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        let handler = Self.lock.withLock { () -> (@Sendable (URLRequest) throws -> StubResponse)? in
            Self.entries[key]?.requests.append(request)
            return Self.entries[key]?.handler
        }

        guard let handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        do {
            let stub = try handler(request)

            guard let url = request.url,
                let response = HTTPURLResponse(
                    url: url,
                    statusCode: stub.statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                )
            else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: stub.body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
