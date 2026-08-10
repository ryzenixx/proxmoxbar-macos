import SwiftUI

struct DashboardToolbar: View {
    @Binding var search: String
    var showsSort: Bool
    var sort: GuestSort
    var onSelectSort: (GuestSort) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            TextField("Search", text: $search)
                .textFieldStyle(.plain)
                .font(.callout)
            if !search.isEmpty {
                Button {
                    search = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Clear")
            }
            if showsSort {
                Divider()
                    .frame(height: 16)
                sortMenu
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 8))
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: sortBinding) {
                ForEach(GuestSort.allCases, id: \.self) { option in
                    Label(option.rawValue, systemImage: option.symbol).tag(option)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 12, weight: .medium))
                Text(sort.rawValue)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Sort order")
    }

    private var sortBinding: Binding<GuestSort> {
        Binding(get: { sort }, set: { onSelectSort($0) })
    }
}
