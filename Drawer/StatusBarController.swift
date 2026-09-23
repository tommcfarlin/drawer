import AppKit
import os

/// Owns Drawer's three menu bar items, left to right: the `[` handle, the `|` wall,
/// and the front.
///
/// Everything between the handle and the wall is in the drawer. Closing stretches
/// the wall so wide that it, the handle, and everything left of it are pushed
/// off-screen. The front, which takes no space while open, then shows `[|` in their
/// place.
@MainActor
final class StatusBarController: NSObject {
    private static let stateKey = "drawerState"
    private static let log = Logger(subsystem: "co.pressware.drawer", category: "state")
    private static let restoreInterval: TimeInterval = 0.1
    private static let restoreMaxAttempts = 30

    private let handleItem: NSStatusItem
    private let wallItem: NSStatusItem
    private let frontItem: NSStatusItem
    private let menu = NSMenu()
    private(set) var state: DrawerState = .open

    override init() {
        // New status items are inserted to the left of existing ones, so create them
        // right to left: front, wall, handle.
        frontItem = NSStatusBar.system.statusItem(withLength: 0)
        frontItem.autosaveName = "DrawerFront"
        frontItem.isVisible = true

        wallItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        wallItem.autosaveName = "DrawerWall"
        wallItem.isVisible = true

        handleItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        handleItem.autosaveName = "DrawerHandle"
        handleItem.isVisible = true

        super.init()

        for item in [handleItem, wallItem, frontItem] {
            guard let button = item.button else { continue }
            button.target = self
            button.action = #selector(itemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        let about = NSMenuItem(title: "About Drawer", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Drawer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        handleItem.button?.attributedTitle = Self.title(handleTitle)

        apply(state)
        restoreSavedState()
    }

    /// The menu bar positions its items shortly after launch, reporting placeholder
    /// frames along the way. Wait until both items sit on a screen and have stopped
    /// moving before restoring, so the close guard sees real positions.
    private func restoreSavedState() {
        let saved = restoredState(from: UserDefaults.standard.string(forKey: Self.stateKey))
        guard saved == .closed else {
            setState(saved)
            return
        }

        var previous: (CGRect, CGRect)?
        var attempts = 0

        func check() {
            attempts += 1
            let screens = NSScreen.screens.map(\.frame)
            let handle = handleItem.button?.window?.frame
            let wall = wallItem.button?.window?.frame

            if let handle, let wall,
               isPlaced(handle, on: screens), isPlaced(wall, on: screens),
               let (lastHandle, lastWall) = previous,
               lastHandle == handle, lastWall == wall {
                setState(saved, beepIfRefused: false)
                return
            }
            guard attempts < Self.restoreMaxAttempts else {
                Self.log.notice("Menu bar items never settled; staying open")
                return
            }
            if let handle, let wall { previous = (handle, wall) }
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.restoreInterval) { check() }
        }

        check()
    }

    func setState(_ newState: DrawerState, beepIfRefused: Bool = true) {
        let handleMinX = handleItem.button?.window?.frame.minX
        let wallMinX = wallItem.button?.window?.frame.minX
        Self.log.debug("setState \(newState.rawValue, privacy: .public) handle=\(String(describing: handleMinX), privacy: .public) wall=\(String(describing: wallMinX), privacy: .public)")
        if newState == .closed, !canClose(handleMinX: handleMinX, wallMinX: wallMinX) {
            Self.log.notice("Refused to close: the handle is not left of the wall")
            if beepIfRefused { NSSound.beep() }
            return
        }
        state = newState
        apply(state)
        UserDefaults.standard.set(state.rawValue, forKey: Self.stateKey)
    }

    @objc private func itemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        let wantsMenu = event.type == .rightMouseUp
            || (event.type == .leftMouseUp && event.modifierFlags.contains(.control))
        if wantsMenu {
            let item = [handleItem, wallItem, frontItem].first { $0.button === sender } ?? wallItem
            showMenu(from: item)
        } else {
            setState(state.toggled)
        }
    }

    /// Attach the menu only while it's open so a plain left-click keeps toggling.
    private func showMenu(from item: NSStatusItem) {
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }

    private func apply(_ state: DrawerState) {
        wallItem.length = wallLength(for: state)
        wallItem.button?.attributedTitle = Self.title(state.wallTitle)

        frontItem.length = frontLength(for: state)
        frontItem.button?.attributedTitle = Self.title(state.frontTitle)
        frontItem.button?.isHidden = state == .open

        for item in [handleItem, wallItem, frontItem] {
            item.button?.setAccessibilityLabel(state.accessibilityLabel)
        }
    }

    /// A title in the menu bar's own font.
    private static func title(_ string: String) -> NSAttributedString {
        NSAttributedString(string: string, attributes: [.font: NSFont.menuBarFont(ofSize: 0)])
    }

    @objc private func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Drawer",
            .applicationIcon: NSApp.applicationIconImage as Any,
            .credits: Self.aboutCredits,
        ])
    }

    private static var aboutCredits: NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: style,
        ]

        func link(_ title: String, _ url: String) -> NSAttributedString {
            var linkAttributes = attributes
            linkAttributes[.link] = URL(string: url)!
            return NSAttributedString(string: title, attributes: linkAttributes)
        }

        let credits = NSMutableAttributedString()
        credits.append(NSAttributedString(
            string: "Throw your menu bar icons into a drawer. Pull them out when you need them.\n\n",
            attributes: attributes
        ))
        credits.append(link("Pressware", "https://pressware.co?ref=drawer"))
        credits.append(NSAttributedString(string: " · ", attributes: attributes))
        credits.append(link("Contact", "mailto:support@pressware.co"))
        return credits
    }
}
