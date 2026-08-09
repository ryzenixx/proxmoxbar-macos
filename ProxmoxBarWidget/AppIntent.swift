import AppIntents
import WidgetKit

struct ServerEntity: AppEntity {
    let id: String
    let name: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Server"
    static let defaultQuery = ServerQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct ServerQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ServerEntity] {
        servers().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [ServerEntity] {
        servers()
    }

    func defaultResult() async -> ServerEntity? {
        servers().first
    }

    private func servers() -> [ServerEntity] {
        WidgetSharedStore.read().map { ServerEntity(id: $0.id, name: $0.name) }
    }
}

struct SelectServerIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Select Server"
    static let description = IntentDescription("Choose which Proxmox server this widget shows.")

    @Parameter(title: "Server")
    var server: ServerEntity?
}
