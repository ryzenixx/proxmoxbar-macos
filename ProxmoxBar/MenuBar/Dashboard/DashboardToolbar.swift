import SwiftUI

struct DashboardToolbar: View {
    @Binding var search: String
    var showsSort: Bool
    var sort: GuestSort
    var onSelectSort: (GuestSort) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            TextField("Search", text: $search)
                .textFieldStyle(.plain)
                .font(.callout)
            if !search.isEmpty {
                Button {
                    search = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Clear")
            }
            if showsSort {
                Divider()
                    .frame(height: 14)
                sortMenu
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 8))
    }

    private var sortMenu: some View {
        Menu {
            ForEach(GuestSort.allCases, id: \.self) { option in
                Button {
                    onSelectSort(option)
                } label: {
                    Label(
                        option.rawValue,
                        systemImage: option == sort ? "checkmark" : option.symbol
                    )
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Sort")
    }
}
