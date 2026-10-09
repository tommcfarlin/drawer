import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.migrateFromSandbox()
        statusBarController = StatusBarController()
    }

    private static let migratedKey = "migratedFromSandbox"

    /// Drawer was sandboxed through 0.2.0, so its settings (including where the brackets
    /// were dragged) live in its container. Copy them over once, before the status items
    /// are created, so the brackets stay where they were.
    private static func migrateFromSandbox() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migratedKey) else { return }
        defaults.set(true, forKey: migratedKey)
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let old = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Library/Containers/\(bundleID)/Data/Library/Preferences/\(bundleID).plist")
        guard let saved = NSDictionary(contentsOf: old) as? [String: Any] else { return }
        for (key, value) in saved where defaults.object(forKey: key) == nil {
            defaults.set(value, forKey: key)
        }
    }

    /// Opening Drawer again while it's running always opens the drawer. If macOS ever
    /// hides the archive box (a crowded menu bar, the notch, or System Settings), this
    /// is the way back to your icons.
    @MainActor
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        statusBarController?.setState(.open)
        return false
    }
}
