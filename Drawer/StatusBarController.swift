import AppKit

/// Owns Drawer's two menu bar items: the chevron toggle and the `|` divider.
///
/// Collapsing stretches the divider so wide that every item to its left is
/// pushed off-screen; expanding shrinks it back to a thin `|`.
@MainActor
final class StatusBarController: NSObject {
    private let toggleItem: NSStatusItem
    private let dividerItem: NSStatusItem
    private(set) var state: DrawerState = .expanded

    override init() {
        // New status items are inserted to the left of existing ones, so creating
        // the toggle first puts the divider to its left.
        toggleItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        toggleItem.autosaveName = "DrawerToggle"
        toggleItem.isVisible = true

        dividerItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        dividerItem.autosaveName = "DrawerDivider"
        dividerItem.isVisible = true

        super.init()

        if let button = toggleItem.button {
            button.target = self
            button.action = #selector(toggleClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        if let button = dividerItem.button {
            button.appearsDisabled = true
            button.setAccessibilityLabel("Drawer divider")
        }

        apply(state)
    }

    func setState(_ newState: DrawerState) {
        if newState == .collapsed,
           !canCollapse(dividerMinX: dividerItem.button?.window?.frame.minX,
                        toggleMinX: toggleItem.button?.window?.frame.minX) {
            NSSound.beep()
            return
        }
        state = newState
        apply(state)
    }

    @objc private func toggleClicked(_ sender: NSStatusBarButton) {
        guard NSApp.currentEvent?.type != .rightMouseUp else { return }
        setState(state.toggled)
    }

    private func apply(_ state: DrawerState) {
        dividerItem.length = dividerLength(for: state)
        dividerItem.button?.title = state == .collapsed ? "" : "|"

        if let button = toggleItem.button {
            let image = NSImage(systemSymbolName: state.toggleSymbolName,
                                accessibilityDescription: state.accessibilityLabel)
            image?.isTemplate = true
            button.image = image
            button.setAccessibilityLabel(state.accessibilityLabel)
        }
    }
}
