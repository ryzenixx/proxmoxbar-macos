import Foundation

struct ServerVersionResponse: Decodable {
    struct Version: Decodable {
        let version: String
        let release: String?
        let repoid: String?
        let console: String?
    }

    let data: Version
}
