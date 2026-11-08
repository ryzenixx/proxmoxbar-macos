import SwiftUI
import WidgetKit

struct ProxmoxBarWidget: Widget {
    let kind = "ProxmoxBarWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectServerIntent.self,
            provider: ServerTimelineProvider()
        ) { entry in
            ServerWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Proxmox Server")
        .description("Nodes, machines and load for one of your servers.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
