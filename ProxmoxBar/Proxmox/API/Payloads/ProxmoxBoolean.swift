import Foundation

struct ProxmoxBoolean: Decodable, Hashable, Sendable {
    let value: Bool

    init(_ value: Bool) {
        self.value = value
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let number = try? container.decode(Int.self) {
            value = number != 0
        } else if let text = try? container.decode(String.self) {
            value = ["1", "true", "yes", "on"].contains(text.lowercased())
        } else {
            value = false
        }
    }
}
