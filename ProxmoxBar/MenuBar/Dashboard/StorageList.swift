import SwiftUI

struct StorageList: View {
    let storages: [ProxmoxStorage]

    var body: some View {
        if storages.isEmpty {
            PagePlaceholder(symbol: "internaldrive", message: "No storage yet")
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(storages) { storage in
                        StorageRow(storage: storage)
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.never)
        }
    }
}
