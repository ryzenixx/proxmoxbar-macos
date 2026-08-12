import Foundation

enum DemoCluster {
    static func state() -> ClusterState {
        ClusterState(nodes: nodes, guests: guests, storages: storages, discardedCount: 0)
    }

    private static let gb = 1_073_741_824
    private static let mb = 1_048_576
    private static let tb = 1_073_741_824 * 1024

    private static let nodes: [ProxmoxNode] = [
        node("atlas", cores: 8, cpu: 0.18, memory: 12 * gb, memoryMax: 32 * gb, disk: 120 * gb, diskMax: 500 * gb),
        node("titan", cores: 6, cpu: 0.09, memory: 10 * gb, memoryMax: 24 * gb, disk: 90 * gb, diskMax: 500 * gb),
    ]

    private static let guests: [ProxmoxGuest] = [
        running(100, "pfsense", .virtualMachine, "atlas", cpu: 0.04, cores: 2, memoryMax: 2 * gb, memoryUsed: 0.15, uptime: 5_184_000),
        running(101, "jellyfin", .virtualMachine, "titan", cpu: 0.27, cores: 4, memoryMax: 8 * gb, memoryUsed: 0.48, uptime: 864_000),
        running(102, "immich", .virtualMachine, "atlas", cpu: 0.11, cores: 4, memoryMax: 6 * gb, memoryUsed: 0.41, uptime: 1_209_600),
        running(103, "vaultwarden", .container, "atlas", cpu: 0.01, cores: 1, memoryMax: 512 * mb, memoryUsed: 0.08, uptime: 3_456_000),
        running(104, "paperless", .container, "titan", cpu: 0.06, cores: 2, memoryMax: 2 * gb, memoryUsed: 0.22, uptime: 604_800),
        running(105, "adguard", .container, "atlas", cpu: 0.02, cores: 1, memoryMax: 512 * mb, memoryUsed: 0.11, uptime: 6_048_000),
        running(106, "uptime-kuma", .container, "titan", cpu: 0.03, cores: 1, memoryMax: 1 * gb, memoryUsed: 0.14, uptime: 259_200),
        running(107, "redis", .container, "atlas", cpu: 0.05, cores: 2, memoryMax: 1 * gb, memoryUsed: 0.19, uptime: 432_000),
        running(108, "prometheus", .container, "titan", cpu: 0.09, cores: 2, memoryMax: 4 * gb, memoryUsed: 0.36, uptime: 950_400),
        stopped(109, "truenas", .virtualMachine, "titan", memoryMax: 16 * gb),
        stopped(110, "forgejo", .container, "atlas", memoryMax: 2 * gb),
        stopped(111, "win-server", .virtualMachine, "atlas", memoryMax: 8 * gb),
    ]

    private static let storages: [ProxmoxStorage] = [
        storage("local", type: "dir", node: "atlas", used: 38 * gb, total: 100 * gb, shared: false),
        storage("local-lvm", type: "lvmthin", node: "atlas", used: 220 * gb, total: 500 * gb, shared: false),
        storage("synology-nfs", type: "nfs", node: nil, used: 1800 * gb, total: 4 * tb, shared: true),
        storage("ceph-rbd", type: "rbd", node: nil, used: 640 * gb, total: 2 * tb, shared: true),
    ]

    private static func node(
        _ name: String, cores: Double, cpu: Double, memory: Int, memoryMax: Int, disk: Int, diskMax: Int
    ) -> ProxmoxNode {
        ProxmoxNode(
            id: "node/\(name)",
            name: name,
            status: "online",
            cpu: cpu,
            maxCPUs: cores,
            memory: memory,
            maximumMemory: memoryMax,
            disk: disk,
            maximumDisk: diskMax,
            uptime: 7_776_000,
            level: nil,
            architecture: "x86_64"
        )
    }

    private static func running(
        _ vmid: Int, _ name: String, _ kind: GuestKind, _ node: String,
        cpu: Double, cores: Double, memoryMax: Int, memoryUsed: Double, uptime: Int
    ) -> ProxmoxGuest {
        guest(
            vmid, name, kind, node, .running,
            cpu: cpu, cores: cores, memory: Int(Double(memoryMax) * memoryUsed), memoryMax: memoryMax, uptime: uptime
        )
    }

    private static func stopped(
        _ vmid: Int, _ name: String, _ kind: GuestKind, _ node: String, memoryMax: Int
    ) -> ProxmoxGuest {
        guest(vmid, name, kind, node, .stopped, cpu: nil, cores: 2, memory: nil, memoryMax: memoryMax, uptime: nil)
    }

    private static func guest(
        _ vmid: Int, _ name: String, _ kind: GuestKind, _ node: String, _ status: GuestStatus,
        cpu: Double?, cores: Double, memory: Int?, memoryMax: Int, uptime: Int?
    ) -> ProxmoxGuest {
        ProxmoxGuest(
            id: "\(kind.rawValue)/\(vmid)",
            vmid: vmid,
            kind: kind,
            node: node,
            name: name,
            status: status,
            isTemplate: false,
            lock: nil,
            tags: [],
            pool: nil,
            haState: nil,
            cpu: cpu,
            maxCPUs: cores,
            memory: memory,
            maximumMemory: memoryMax,
            disk: nil,
            maximumDisk: nil,
            uptime: uptime
        )
    }

    private static func storage(
        _ name: String, type: String, node: String?, used: Int, total: Int, shared: Bool
    ) -> ProxmoxStorage {
        ProxmoxStorage(
            id: "storage/\(name)",
            name: name,
            node: node,
            status: "available",
            used: used,
            total: total,
            content: ["images", "rootdir"],
            pluginType: type,
            isShared: shared
        )
    }
}
