import Foundation

struct ClusterCapacity: Hashable, Sendable {
    let used: Int
    let total: Int

    var ratio: Double {
        guard total > 0 else { return 0 }
        return min(Double(used) / Double(total), 1)
    }

    var summary: String {
        let used = Int64(self.used).formatted(.byteCount(style: .memory))
        let total = Int64(self.total).formatted(.byteCount(style: .memory))
        return "\(used) of \(total)"
    }
}
