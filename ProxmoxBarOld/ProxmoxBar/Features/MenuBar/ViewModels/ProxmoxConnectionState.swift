import Foundation

/// What the dashboard shows about the current connection.
///
/// This is view state, not API state: the loading and error cases carry text
/// meant for a human. The client in `ProxmoxBarCore` returns data or throws, and
/// the view model decides what that looks like.
enum ProxmoxServiceStatus {
    case running
    case stopped
    case loading(String)
    case error(String)
}
