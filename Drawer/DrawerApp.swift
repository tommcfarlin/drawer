import SwiftUI

@main
struct DrawerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Drawer lives entirely in the menu bar; there are no windows.
        Settings {
            EmptyView()
        }
    }
}
