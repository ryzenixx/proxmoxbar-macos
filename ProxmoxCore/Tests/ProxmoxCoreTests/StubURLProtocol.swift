import Foundation

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    struct Response {
        let statusCode: Int
        let body: Data

        static func ok(_ body: Data) -> Response { Response(statusCode: 200, body: body) }
        static func status(_ code: Int, _ body: String = "") -> Response {
            Response(statusCode: code, body: Data(body.utf8))
        }
    }

    nonisolated(unsafe) private static var handler: (@Sendable (URLRequest) throws -> Response)?
    nonisolated(unsafe) private(set) static var requests: [URLRequest] = []
    private static let lock = NSLock()

    static func install(_ handler: @escaping @Sendable (URLRequest) throws -> Response)
        -> URLSessionConfiguration
    {
        lock.withLock {
            self.handler = handler
            requests = []
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return configuration
    }

    static var lastRequest: URLRequest? {
        lock.withLock { requests.last }
    }

    static var requestCount: Int {
        lock.withLock { requests.count }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let handler = Self.lock.withLock {
            Self.requests.append(request)
            return Self.handler
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
