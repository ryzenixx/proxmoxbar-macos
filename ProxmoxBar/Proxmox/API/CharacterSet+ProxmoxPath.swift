import Foundation

extension CharacterSet {
    static let proxmoxPathSegment = CharacterSet.alphanumerics.union(
        CharacterSet(charactersIn: "-._~")
    )
}
