struct ProxmoxServer: Hashable, Sendable {
    let credentials: ServerCredentials
    let pinnedFingerprint: String?

    init(credentials: ServerCredentials, pinnedFingerprint: String? = nil) {
        self.credentials = credentials
        self.pinnedFingerprint = pinnedFingerprint
    }
}
