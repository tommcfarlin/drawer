import AppKit
import os

/// Owns Drawer's two menu bar items: the chevron toggle and the `|` divider.
///
/// Collapsing stretches the divider so wide that every item to its left is
/// pushed off-screen; expanding shrinks it back to a thin `|`.
@MainActor
final class StatusBarController: NSObject {
    private static let stateKey = "drawerState"
    private static let log = Logger(subsystem: "co.pressware.drawer", category: "state")
    private static let restoreInterval: TimeInterval = 0.1
    private static let restoreMaxAttempts = 30

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

        restoreSavedState()
    }

    /// The menu bar positions its items shortly after launch, reporting placeholder
    /// frames along the way. Wait until both items sit on a screen and have stopped
    /// moving before restoring, so the collapse guard sees real positions.
    private func restoreSavedState() {
        let saved = restoredState(from: UserDefaults.standard.string(forKey: Self.stateKey))
        guard saved == .collapsed else {
            setState(saved)
            return
        }

        var previous: (CGRect, CGRect)?
        var attempts = 0

        func check() {
            attempts += 1
            let screens = NSScreen.screens.map(\.frame)
            let divider = dividerItem.button?.window?.frame
            let toggle = toggleItem.button?.window?.frame

            if let divider, let toggle,
               isPlaced(divider, on: screens), isPlaced(toggle, on: screens),
               let (lastDivider, lastToggle) = previous,
               lastDivider == divider, lastToggle == toggle {
                setState(saved, beepIfRefused: false)
                return
            }
            guard attempts < Self.restoreMaxAttempts else {
                Self.log.notice("Menu bar items never settled; staying expanded")
                return
            }
            if let divider, let toggle { previous = (divider, toggle) }
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.restoreInterval) { check() }
        }

        check()
    }

    func setState(_ newState: DrawerState, beepIfRefused: Bool = true) {
        let dividerMinX = dividerItem.button?.window?.frame.minX
        let toggleMinX = toggleItem.button?.window?.frame.minX
        Self.log.debug("setState \(newState.rawValue, privacy: .public) divider=\(String(describing: dividerMinX), privacy: .public) toggle=\(String(describing: toggleMinX), privacy: .public)")
        if newState == .collapsed, !canCollapse(dividerMinX: dividerMinX, toggleMinX: toggleMinX) {
            Self.log.notice("Refused to collapse: divider is not left of the toggle")
            if beepIfRefused { NSSound.beep() }
            return
        }
        state = newState
        apply(state)
        UserDefaults.standard.set(state.rawValue, forKey: Self.stateKey)
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
