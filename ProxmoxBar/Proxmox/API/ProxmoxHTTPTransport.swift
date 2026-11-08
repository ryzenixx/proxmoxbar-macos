import Foundation

actor ProxmoxHTTPTransport {
    private static let requestTimeout: TimeInterval = 10

    private struct Transport {
        let session: URLSession
        let delegate: ProxmoxSessionDelegate
    }

    private let configuration: URLSessionConfiguration
    private var transports: [ProxmoxServer: Transport] = [:]

    init(configuration: URLSessionConfiguration = .ephemeral) {
        configuration.timeoutIntervalForRequest = Self.requestTimeout
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.configuration = configuration
    }

    enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
    }

    func request<Payload: Decodable & Sendable>(
        _ segments: [String],
        method: Method = .get,
        from server: ProxmoxServer
    ) async throws -> Payload {
        let request = try makeRequest(segments, method: method, server: server)
        let data = try await send(request, to: server)
        return try decode(ProxmoxResponse<Payload>.self, from: data).data
    }

    private func makeRequest(
        _ segments: [String],
        method: Method,
        server: ProxmoxServer
    ) throws -> URLRequest {
        var request = URLRequest(url: try url(for: segments, of: server))
        request.httpMethod = method.rawValue
        request.setValue(
            server.credentials.authorizationHeader,
            forHTTPHeaderField: "Authorization"
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if method == .post {
            request.setValue(
                "application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type"
            )
            request.httpBody = Data()
        }
        return request
    }

    private func url(for segments: [String], of server: ProxmoxServer) throws -> URL {
        var components = URLComponents(
            url: server.credentials.baseURL,
            resolvingAgainstBaseURL: false
        )
        let escaped = segments.map {
            $0.addingPercentEncoding(withAllowedCharacters: .proxmoxPathSegment) ?? $0
        }
        components?.percentEncodedPath = "/api2/json/" + escaped.joined(separator: "/")
        guard let url = components?.url else { throw ProxmoxError.invalidURL }
        return url
    }

    private func send(_ request: URLRequest, to server: ProxmoxServer) async throws -> Data {
        let transport = transport(for: server)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.session.data(for: request)
        } catch let error as URLError {
            if let rejection = transport.delegate.takeRejection() {
                throw rejection
            }
            if error.code == .cancelled {
                throw CancellationError()
            }
            if error.code == .timedOut {
                throw ProxmoxError.timedOut
            }
            throw ProxmoxError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ProxmoxError.transport("The server sent a response that was not HTTP.")
        }
        switch http.statusCode {
        case 200..<300: return data
        case 401: throw ProxmoxError.unauthorized
        case 403: throw ProxmoxError.forbidden
        case 404: throw ProxmoxError.notFound
        default:
            throw ProxmoxError.httpError(
                status: http.statusCode,
                reason: try? JSONDecoder()
                    .decode(ProxmoxFailurePayload.self, from: data)
                    .reason
            )
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw ProxmoxError.decoding(error.localizedDescription)
        }
    }

    private func transport(for server: ProxmoxServer) -> Transport {
        if let existing = transports[server] { return existing }
        let delegate = ProxmoxSessionDelegate(
            evaluator: ServerTrustEvaluator(pinnedFingerprint: server.pinnedFingerprint)
        )
        let session = URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )
        let transport = Transport(session: session, delegate: delegate)
        transports[server] = transport
        return transport
    }
}
