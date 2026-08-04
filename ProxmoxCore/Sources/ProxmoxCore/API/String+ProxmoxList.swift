import Foundation

extension String {
    var proxmoxList: [String] {
        split(whereSeparator: { $0 == ";" || $0 == "," || $0 == " " })
            .map(String.init)
            .filter { !$0.isEmpty }
    }
}
