import SwiftUI

struct HelpLink: View {
    let title: String
    let symbol: String?
    let destination: URL

    init(_ title: String, symbol: String? = nil, destination: URL) {
        self.title = title
        self.symbol = symbol
        self.destination = destination
    }

    var body: some View {
        Link(destination: destination) {
            HStack(spacing: 4) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 10))
                }
                Text(title)
                    .underline()
            }
            .foregroundStyle(.primary)
        }
    }
}
