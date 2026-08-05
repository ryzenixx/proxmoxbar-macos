import Foundation
import Synchronization

final class ProxmoxSessionDelegate: NSObject, URLSessionDelegate, Sendable {
    private let evaluator: ServerTrustEvaluator
    private let rejection = Mutex<ProxmoxError?>(nil)

    init(evaluator: ServerTrustEvaluator) {
        self.evaluator = evaluator
    }

    func takeRejection() -> ProxmoxError? {
        rejection.withLock { stored in
            defer { stored = nil }
            return stored
        }
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let trust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        switch evaluator.evaluate(trust) {
        case .trusted:
            completionHandler(.useCredential, URLCredential(trust: trust))
        case .needsApproval(let certificate):
            store(.untrustedCertificate(certificate))
            completionHandler(.cancelAuthenticationChallenge, nil)
        case .rejected(let error):
            store(error)
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    private func store(_ error: ProxmoxError) {
        rejection.withLock { $0 = error }
    }
}
