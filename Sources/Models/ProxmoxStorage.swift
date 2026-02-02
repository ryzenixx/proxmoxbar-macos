import Foundation

struct ProxmoxStorage: Identifiable, Codable {
    var id: String {
        return "\(node)-\(storage)"
    }
    let storage: String
    let node: String
    let status: String
    
    let disk: Int64?
    let maxdisk: Int64?
    let type: String?
    let content: String?
    
    var isAvailable: Bool {
        return status == "available"
    }

    var diskUsage: Double {
        guard let disk = disk, let maxdisk = maxdisk, maxdisk > 0 else { return 0.0 }
        return Double(disk) / Double(maxdisk)
    }

    var diskUsageFormatted: String {
        guard let disk = disk, let maxdisk = maxdisk, maxdisk > 0 else { return "-" }
        let percent = (Double(disk) / Double(maxdisk)) * 100
        return String(format: "%.0f%%", percent)
    }
}
