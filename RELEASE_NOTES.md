# Release 1.0.2 🖥️

### Added
- **Cluster Stats**: Added a unified "Datacenter" view in the header showing aggregated CPU, RAM, and Disk usage for the entire cluster.
- **Storage**: Improved storage calculation by retrieving all storage pools from the cluster (`/cluster/resources`), ensuring accurate total disk usage reporting.
- **UI**: Added dynamic color coding for resource gauges (Gray/Orange/Red) based on usage thresholds.

### Changed
- **Architecture**: Refactored statistics to focus on Cluster-level aggregation rather than individual nodes in the header.
- **UI**: Simplified the header statistics display for a cleaner, reliable look.
