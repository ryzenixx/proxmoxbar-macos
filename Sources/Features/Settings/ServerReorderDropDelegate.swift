import SwiftUI

struct ServerReorderDropDelegate: DropDelegate {
    let destinationItem: ProxmoxServerConfig
    @Binding var servers: [ProxmoxServerConfig]
    @Binding var draggedItem: ProxmoxServerConfig?

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem, draggedItem != destinationItem else {
            return
        }
        guard let fromIndex = servers.firstIndex(of: draggedItem),
              let toIndex = servers.firstIndex(of: destinationItem) else {
            return
        }

        withAnimation {
            servers.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }
}
