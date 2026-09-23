import AppKit
import os

/// Owns Drawer's three menu bar items, left to right: the `[` handle, the `]` wall,
/// and the front.
///
/// Everything between the handle and the wall is in the drawer. Closing stretches
/// the wall so wide that it, the handle, and everything left of it are pushed
/// off-screen. The front, which only exists while closed, then shows an archive box
/// in their place.
@MainActor
final class StatusBarController: NSObject {
    private static let stateKey = "drawerState"
    private static let log = Logger(subsystem: "co.pressware.drawer", category: "state")
    private static let restoreInterval: TimeInterval = 0.1
    private static let restoreMaxAttempts = 30
    private static let frontPositionKey = "NSStatusItem Preferred Position DrawerFront"
    private static let wallPositionKey = "NSStatusItem Preferred Position DrawerWall"
    /// How long to wait after closing before confirming the front is on screen.
    private static let frontCheckDelay: TimeInterval = 0.3

    private let handleItem: NSStatusItem
    private let wallItem: NSStatusItem
    private let frontItem: NSStatusItem
    private(set) var state: DrawerState = .open

    override init() {
        // New status items are inserted to the left of existing ones, so create them
        // right to left: front, wall, handle.
        frontItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        frontItem.autosaveName = "DrawerFront"
        // Start visible so the menu bar records the front's spot just right of the
        // wall; it's hidden once launch settles if the drawer is open. Hiding it
        // before it has a spot would bring it back at the far left, off-screen.
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
            // VoiceOver can't right-click, so offer the menu as a custom action.
            button.setAccessibilityCustomActions([
                NSAccessibilityCustomAction(name: "Show Menu") { [weak self, weak item] in
                    guard let self, let item else { return false }
                    self.showMenu(from: item)
                    return true
                },
            ])
        }

        handleItem.button?.image = Self.bracket(opening: true)
        wallItem.button?.image = Self.bracket(opening: false)
        frontItem.button?.image = Self.closedImage

        restoreSavedState()
    }

    /// The menu bar positions its items shortly after launch, reporting placeholder
    /// frames along the way. Wait until all three items sit on a screen and have
    /// stopped moving before restoring, so the close guard sees real positions and
    /// the front has a recorded spot before it's hidden.
    private func restoreSavedState() {
        let saved = restoredState(from: UserDefaults.standard.string(forKey: Self.stateKey))
        let items = [handleItem, wallItem, frontItem]
        var previous: [CGRect]?
        var attempts = 0

        func check() {
            attempts += 1
            let screens = NSScreen.screens.map(\.frame)
            let frames = items.compactMap { $0.button?.window?.frame }

            if frames.count == items.count,
               frames.allSatisfy({ isPlaced($0, on: screens) }),
               frames == previous {
                setState(saved, beepIfRefused: false)
                if state != saved { apply(state) }
                return
            }
            guard attempts < Self.restoreMaxAttempts else {
                Self.log.notice("Menu bar items never settled; opening the drawer")
                state = .open
                apply(state)
                return
            }
            previous = frames
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.restoreInterval) { check() }
        }

        check()
    }

    /// Returns whether the change happened. Closing is refused if the handle isn't
    /// left of the wall.
    @discardableResult
    func setState(_ newState: DrawerState, beepIfRefused: Bool = true) -> Bool {
        let handleMinX = handleItem.button?.window?.frame.minX
        let wallMinX = wallItem.button?.window?.frame.minX
        Self.log.debug("setState \(newState.rawValue, privacy: .public) handle=\(String(describing: handleMinX), privacy: .public) wall=\(String(describing: wallMinX), privacy: .public)")
        if newState == .closed, !canClose(handleMinX: handleMinX, wallMinX: wallMinX) {
            Self.log.notice("Refused to close: the handle is not left of the wall")
            if beepIfRefused { NSSound.beep() }
            return false
        }
        state = newState
        apply(state)
        UserDefaults.standard.set(state.rawValue, forKey: Self.stateKey)
        return true
    }

    @objc private func itemClicked(_ sender: NSStatusBarButton) {
        let item = [handleItem, wallItem, frontItem].first { $0.button === sender } ?? wallItem
        let event = NSApp.currentEvent
        switch clickAction(eventType: event?.type, modifiers: event?.modifierFlags ?? []) {
        case .showMenu:
            showMenu(from: item)
        case .toggle:
            if !setState(state.toggled) {
                // A beep alone is easy to miss; say why, right where they clicked.
                showMenu(from: item, notice: Self.misplacedHandleNotice)
            }
        }
    }

    /// Same as a left-click, including explaining a refusal.
    @objc private func toggleFromMenu() {
        if !setState(state.toggled) {
            showMenu(from: wallItem, notice: Self.misplacedHandleNotice)
        }
    }

    private static let misplacedHandleNotice = "Move [ to the Left of ] to Use the Drawer"

    /// Attach the menu only while it's open so a plain left-click keeps toggling.
    private func showMenu(from item: NSStatusItem, notice: String? = nil) {
        item.menu = makeMenu(notice: notice)
        item.button?.performClick(nil)
        item.menu = nil
    }

    /// Built each time it opens so its contents can reflect the current state.
    /// A notice, if given, appears first as a dimmed, unclickable line.
    private func makeMenu(notice: String?) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        if let notice {
            let line = NSMenuItem(title: notice, action: nil, keyEquivalent: "")
            line.isEnabled = false
            menu.addItem(line)
            menu.addItem(.separator())
        }

        let toggle = NSMenuItem(title: state.menuActionTitle, action: #selector(toggleFromMenu), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())

        let about = NSMenuItem(title: "About Drawer", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Drawer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        return menu
    }

    private func apply(_ state: DrawerState) {
        if state.showsFront && !frontItem.isVisible {
            // A re-shown item lands wherever its saved position says, and the menu bar
            // doesn't save one on its own. Point it just right of the wall, and show it
            // before the wall stretches so it isn't pushed off-screen with it.
            positionFrontNextToWall()
            frontItem.isVisible = true
            confirmFrontIsShowing()
        }
        wallItem.length = wallLength(for: state)
        if !state.showsFront { frontItem.isVisible = false }

        for item in [handleItem, wallItem, frontItem] {
            item.button?.setAccessibilityLabel(state.accessibilityLabel)
        }
    }

    /// Positions only order correctly against other saved positions, so make sure the
    /// wall has one (recording where it already is doesn't move it), then place the
    /// front just below it.
    private func positionFrontNextToWall() {
        let defaults = UserDefaults.standard
        var wallPosition = defaults.object(forKey: Self.wallPositionKey) as? Double
        if wallPosition == nil, let wall = wallItem.button?.window, let screen = wall.screen {
            wallPosition = preferredPosition(itemMaxX: wall.frame.maxX, screenMaxX: screen.frame.maxX)
            defaults.set(wallPosition, forKey: Self.wallPositionKey)
        }
        guard let wallPosition else { return }
        let front = frontPreferredPosition(wallPosition: wallPosition)
        defaults.set(front, forKey: Self.frontPositionKey)
        Self.log.debug("wall position \(wallPosition, privacy: .public), front position \(front, privacy: .public)")
    }

    /// Safety net: if the front didn't land on screen, there'd be nothing to click to
    /// reopen the drawer, so reopen it.
    private func confirmFrontIsShowing() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.frontCheckDelay) { [weak self] in
            guard let self, self.state == .closed else { return }
            let screens = NSScreen.screens.map(\.frame)
            guard let frame = self.frontItem.button?.window?.frame, isPlaced(frame, on: screens) else {
                Self.log.error("The closed drawer didn't appear on screen; reopening")
                self.setState(.open)
                return
            }
        }
    }

    // MARK: - Images

    /// `[` or `]`, drawn to match SF Symbols' regular weight at menu bar size.
    private static func bracket(opening: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 7, height: 16), flipped: false) { _ in
            let path = NSBezierPath()
            path.lineWidth = 1.5
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            let tips: CGFloat = opening ? 5.5 : 1.5
            let spine: CGFloat = opening ? 1.5 : 5.5
            path.move(to: NSPoint(x: tips, y: 1.5))
            path.line(to: NSPoint(x: spine, y: 1.5))
            path.line(to: NSPoint(x: spine, y: 14.5))
            path.line(to: NSPoint(x: tips, y: 14.5))
            NSColor.black.setStroke()
            path.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }

    private static var closedImage: NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let image = NSImage(systemSymbolName: closedSymbolName, accessibilityDescription: "Drawer")?
            .withSymbolConfiguration(config)
        image?.isTemplate = true
        return image
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
