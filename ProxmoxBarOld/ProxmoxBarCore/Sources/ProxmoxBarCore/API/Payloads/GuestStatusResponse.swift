import Foundation

struct GuestStatusResponse: Decodable {
    struct Status: Decodable {
        struct HighAvailability: Decodable {
            let managed: ProxmoxBoolean?
        }

        let vmid: Int
        let name: String?
        let status: String
        let qmpstatus: String?
        let lock: String?
        let tags: String?

        let cpu: Double?
        let cpus: Double?
        let mem: Int64?
        let maxmem: Int64?
        let memhost: Int64?
        let swap: Int64?
        let maxswap: Int64?
        let disk: Int64?
        let maxdisk: Int64?
        let uptime: Int?

        let netin: Int64?
        let netout: Int64?
        let diskread: Int64?
        let diskwrite: Int64?

        let ha: HighAvailability?
        let agent: ProxmoxBoolean?
    }

    let data: Status
}
