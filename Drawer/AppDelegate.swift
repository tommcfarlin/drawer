import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
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
