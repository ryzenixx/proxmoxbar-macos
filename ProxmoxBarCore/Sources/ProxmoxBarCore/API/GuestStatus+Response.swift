import Foundation

extension GuestStatus {
    init(_ payload: GuestStatusResponse.Status) {
        self.init(
            vmid: payload.vmid,
            name: payload.name,
            status: payload.status,
            qmpStatus: payload.qmpstatus,
            lock: payload.lock,
            tags: payload.tags?.proxmoxList ?? [],
            cpu: payload.cpu,
            cpus: payload.cpus,
            mem: payload.mem,
            maxmem: payload.maxmem,
            hostMemory: payload.memhost,
            swap: payload.swap,
            maxswap: payload.maxswap,
            disk: payload.disk,
            maxdisk: payload.maxdisk,
            uptime: payload.uptime,
            networkIn: payload.netin,
            networkOut: payload.netout,
            diskRead: payload.diskread,
            diskWritten: payload.diskwrite,
            isManagedByHA: payload.ha?.managed?.value ?? false,
            hasGuestAgent: payload.agent?.value ?? false
        )
    }
}

extension ServerVersion {
    init(_ payload: ServerVersionResponse.Version) {
        self.init(
            version: payload.version,
            release: payload.release,
            repositoryId: payload.repoid,
            console: payload.console
        )
    }
}
