import AppKit
import QuartzCore
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
    /// How long to wait after a change before measuring the notch.
    private static let notchRefreshDelay: TimeInterval = 0.4
    /// How long to wait after closing before confirming the front is on screen.
    private static let frontCheckDelay: TimeInterval = 0.3

    private let wallImage = StatusBarController.bracket(opening: false)
    private let closedImageValue = StatusBarController.closedImage
    /// Overlays that briefly stand in for the wall's and front's images while they bounce.
    private let wallFace = NSImageView()
    private let frontFace = NSImageView()

    private let handleItem: NSStatusItem
    private let wallItem: NSStatusItem
    private let frontItem: NSStatusItem
    private(set) var state: DrawerState = .open
    /// Explanations are only shown for changes the user asked for, never at launch.
    private var lastChangeWasUserInitiated = false

    override init() {
        // The front is created before anything can be measured. Without a saved
        // position it would land at the far left of the menu bar, where a closed drawer
        // pushes it off-screen. If the wall has a saved position, seed the front's.
        Self.seedFrontPosition()

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
                NSAccessibilityCustomAction(name: String(localized: "Show Menu")) { [weak self, weak item] in
                    guard let self, let item else { return false }
                    self.showMenu(from: item)
                    return true
                },
            ])
        }

        handleItem.button?.image = Self.bracket(opening: true)
        wallItem.button?.image = wallImage
        frontItem.button?.image = closedImageValue
        for (face, item) in [(wallFace, wallItem), (frontFace, frontItem)] {
            face.isHidden = true
            face.wantsLayer = true
            // Purely visual; the button already carries the label and help.
            face.setAccessibilityElement(false)
            item.button?.addSubview(face)
        }

        restoreSavedState()

        // Plugging in or removing a display changes what fits beside the notch.
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.notchRefreshDelay) { self?.refreshNotchTooltip() }
            }
        }
    }

    private var parts: [(DrawerPart, NSStatusItem)] {
        [(.handle, handleItem), (.wall, wallItem), (.front, frontItem)]
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
                setState(saved, userInitiated: false)
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
    func setState(_ newState: DrawerState, userInitiated: Bool = true) -> Bool {
        guard !isNoOp(current: state, requested: newState, userInitiated: userInitiated) else { return true }
        let handleMinX = handleItem.button?.window?.frame.minX
        let wallMinX = wallItem.button?.window?.frame.minX
        Self.log.debug("setState \(newState.rawValue, privacy: .public) handle=\(String(describing: handleMinX), privacy: .public) wall=\(String(describing: wallMinX), privacy: .public)")
        if newState == .closed, !canClose(handleMinX: handleMinX, wallMinX: wallMinX) {
            Self.log.notice("Refused to close: the handle is not left of the wall")
            if userInitiated { NSSound.beep() }
            return false
        }
        state = newState
        lastChangeWasUserInitiated = userInitiated
        apply(state)
        UserDefaults.standard.set(state.rawValue, forKey: Self.stateKey)
        if userInitiated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            switch state {
            case .closed: bounce(frontItem, face: frontFace, image: closedImageValue, nativeSymbol: true)
            case .open: bounce(wallItem, face: wallFace, image: wallImage, nativeSymbol: false)
            }
        }
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

    private static let helpURL = URL(string: "https://github.com/tommcfarlin/drawer#setup")!

    @objc private func showHelp() {
        NSWorkspace.shared.open(Self.helpURL)
    }

    private static let menuBarFullNotice = String(localized: "The Menu Bar Is Too Full to Close the Drawer")
    private static let misplacedHandleNotice = String(localized: "Move [ to the Left of ] to Use the Drawer")

    /// Attach the menu only while it's open so a plain left-click keeps toggling.
    private func showMenu(from item: NSStatusItem, notice: String? = nil) {
        item.menu = makeMenu(notice: notice)
        item.button?.performClick(nil)
        item.menu = nil
    }

    /// Built each time it opens so its contents can reflect the current state.
    /// A notice, if given, appears first as a dimmed, unclickable line; otherwise the
    /// notch hint does, when there is one.
    private func makeMenu(notice: String?) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        // A refused or failed close takes priority over the notch hint.
        let lines = notice.map { [$0] } ?? notchHint(for: currentNotchFit())
        if !lines.isEmpty {
            for text in lines {
                let line = NSMenuItem(title: text, action: nil, keyEquivalent: "")
                line.isEnabled = false
                menu.addItem(line)
            }
            menu.addItem(.separator())
        }

        let toggle = NSMenuItem(title: state.menuActionTitle, action: #selector(toggleFromMenu), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())

        let help = NSMenuItem(title: String(localized: "How to Use Drawer…"), action: #selector(showHelp), keyEquivalent: "")
        help.target = self
        menu.addItem(help)

        let about = NSMenuItem(title: String(localized: "About Drawer"), action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: String(localized: "Quit Drawer"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        return menu
    }

    private func apply(_ state: DrawerState) {
        if state.showsFront {
            if !frontItem.isVisible {
                // A re-shown item lands wherever its saved position says, and the menu
                // bar doesn't save one on its own. Point it just right of the wall, and
                // show it before the wall stretches so it isn't pushed off-screen with it.
                positionFrontNextToWall()
                frontItem.isVisible = true
            }
            // Every close is checked, including a launch into the closed state: a
            // missing front means there's nothing to click to get the icons back.
            confirmFrontIsShowing()
        }
        wallItem.length = wallLength(for: state)
        if !state.showsFront { frontItem.isVisible = false }

        for (part, item) in parts {
            item.button?.setAccessibilityLabel(accessibilityLabel(for: part))
            item.button?.setAccessibilityHelp(accessibilityHelp(for: state))
            item.button?.toolTip = state.menuActionTitle
        }
        // Measure once the menu bar has laid out the change.
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.notchRefreshDelay) { [weak self] in
            self?.refreshNotchTooltip()
        }
    }

    /// Adds the notch hint's first line to the tooltip of the drawer's visible edge:
    /// `]` while open, the archive box while closed.
    private func refreshNotchTooltip() {
        let edge = state == .open ? wallItem : frontItem
        guard let first = notchHint(for: currentNotchFit()).first else {
            edge.button?.toolTip = state.menuActionTitle
            return
        }
        edge.button?.toolTip = state.menuActionTitle + "\n" + first
    }

    private static func seedFrontPosition() {
        let defaults = UserDefaults.standard
        guard let seeded = seededFrontPosition(savedWallPosition: defaults.object(forKey: wallPositionKey) as? Double) else { return }
        defaults.set(seeded, forKey: frontPositionKey)
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
            let placed = (self.frontItem.button?.window?.frame).map { isPlaced($0, on: screens) } ?? false
            guard placed else {
                Self.log.error("The closed drawer didn't appear on screen; reopening")
                let explain = self.lastChangeWasUserInitiated
                self.setState(.open, userInitiated: false)
                if explain {
                    Self.log.notice("Explaining the reopen to the user")
                    self.showMenu(from: self.wallItem, notice: Self.menuBarFullNotice)
                }
                return
            }
        }
    }

    // MARK: - Notch

    /// How the notch affects the drawer, worst case across notched displays.
    func currentNotchFit() -> NotchFit {
        // Drawer's own frames may come from any display's menu bar copy; carry each one
        // over to the notched display by its distance from the right edge.
        func offset(of item: NSStatusItem) -> CGFloat? {
            guard let window = item.button?.window, let screen = window.screen, item.isVisible else { return nil }
            return offsetFromRightEdge(itemMinX: window.frame.minX, screenMaxX: screen.frame.maxX)
        }
        let handleOffset = state == .open ? offset(of: handleItem) : nil
        let edgeOffset = state == .open ? offset(of: wallItem) : offset(of: frontItem)

        let fits = MenuBarWindows.notchedDisplays().map { display in
            notchFit(
                items: display.windows,
                handleMinX: handleOffset.map { minX(atOffsetFromRightEdge: $0, screenMaxX: display.screenMaxX) },
                wallMinX: edgeOffset.map { minX(atOffsetFromRightEdge: $0, screenMaxX: display.screenMaxX) }
            )
        }
        let result = worst(fits)
        Self.log.debug("notch fit: \(String(describing: result), privacy: .public) across \(fits.count, privacy: .public) notched display(s)")
        return result
    }

    // MARK: - Bounce

    /// A quick bounce on the drawer's own icon: the archive box as it shuts, `]` as it
    /// opens. Other apps' icons can't be animated, so the motion stays on Drawer's.
    /// The button's image is swapped for a clear placeholder and an overlay for the
    /// length of the bounce, then restored, so the resting state is exactly as before.
    private func bounce(_ item: NSStatusItem, face: NSImageView, image: NSImage?, nativeSymbol: Bool) {
        // Wait a turn so a just-shown item has been laid out.
        DispatchQueue.main.async { [weak self] in
            guard let self, let button = item.button, let image else { return }
            face.image = image
            face.frame = CGRect(
                x: ((button.bounds.width - image.size.width) / 2).rounded(),
                y: ((button.bounds.height - image.size.height) / 2).rounded(),
                width: image.size.width,
                height: image.size.height
            )
            // A clear image of the same size keeps the item's width; with no image the
            // menu bar would shrink it and shift its neighbors for the bounce.
            button.image = NSImage(size: image.size)
            let placeholder = button.image
            face.isHidden = false

            if nativeSymbol {
                face.addSymbolEffect(.bounce, options: .nonRepeating)
            } else if let layer = face.layer {
                layer.add(Self.bounceAnimation(for: face.bounds), forKey: "bounce")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + bounceDuration + 0.1) { [weak self] in
                face.isHidden = true
                face.removeAllSymbolEffects()
                face.layer?.removeAnimation(forKey: "bounce")
                // Only restore if nothing changed the item since.
                if self != nil, button.image === placeholder { button.image = image }
            }
        }
    }

    /// Scales around the view's center (a layer-backed view's anchor is its corner).
    private static func bounceAnimation(for bounds: CGRect) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.values = bounceScales.map { scale in
            var t = CATransform3DMakeTranslation(bounds.midX, bounds.midY, 0)
            t = CATransform3DScale(t, scale, scale, 1)
            t = CATransform3DTranslate(t, -bounds.midX, -bounds.midY, 0)
            return NSValue(caTransform3D: t)
        }
        animation.keyTimes = bounceKeyTimes.map { NSNumber(value: $0) }
        animation.duration = bounceDuration
        animation.timingFunctions = Array(repeating: CAMediaTimingFunction(name: .easeInEaseOut), count: bounceScales.count - 1)
        return animation
    }

    // MARK: - Images

    /// `[` or `]`, matching SF Symbols' regular weight at menu bar size. The drawing
    /// handler runs once per backing scale, so each display gets pixel-aligned strokes.
    private static func bracket(opening: Bool) -> NSImage {
        let image = NSImage(size: bracketSize, flipped: false) { _ in
            let ctm = NSGraphicsContext.current?.cgContext.ctm
            let scale = ctm.map { max(abs($0.a), abs($0.b)) } ?? 2
            NSColor.black.setFill()
            bracketRects(opening: opening, scale: scale).forEach { $0.fill() }
            return true
        }
        image.isTemplate = true
        return image
    }

    private static var closedImage: NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let image = NSImage(systemSymbolName: closedSymbolName, accessibilityDescription: String(localized: "Closed drawer"))?
            .withSymbolConfiguration(config)
        image?.isTemplate = true
        return image
    }

    @objc private func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: String(localized: "Drawer", comment: "App name"),
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
            string: String(localized: "Throw your menu bar icons into a drawer. Pull them out when you need them.") + "\n\n",
            attributes: attributes
        ))
        credits.append(link(String(localized: "Pressware", comment: "Company name"), "https://pressware.co?ref=drawer"))
        credits.append(NSAttributedString(string: " · ", attributes: attributes))
        credits.append(link(String(localized: "Contact"), "mailto:support@pressware.co"))
        return credits
    }
}
