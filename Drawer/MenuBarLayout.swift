import AppKit

/// Reads the macOS 27 menu bar through Accessibility, to find which apps' icons are in
/// the drawer. From macOS 27, `MenuBarAgent` draws each display's menu bar as one window,
/// so status items are no longer in the window list, and AppKit reports Drawer's own
/// frames from whichever display's copy it likes. The Accessibility tree has every
/// display's real layout: one window per display, one slot per status item, each with
/// the process that owns it. Needs Accessibility permission.
enum MenuBarLayout {
    /// One display's menu bar, in Accessibility coordinates (same x as AppKit).
    struct Display {
        let frame: CGRect
        let slots: [Slot]

        /// The slot for one of Drawer's items, matched by its window's width.
        func slot(for item: NSStatusItem) -> MenuBarSlot? {
            guard let width = item.button?.window?.frame.width else { return nil }
            return uniqueSlot(width: width, among: slots.filter(\.isDrawers).map(\.slot))
        }
    }

    struct Slot {
        let slot: MenuBarSlot
        /// The app that owns the status item (`MenuBarAgent` for system items).
        let owner: pid_t
        let isDrawers: Bool
    }

    static let agentBundleID = "com.apple.MenuBarAgent"
    private static let messagingTimeout: Float = 0.5

    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Shows the system prompt that leads to System Settings → Privacy & Security →
    /// Accessibility. Returns whether Drawer is already allowed.
    @discardableResult
    static func requestTrust() -> Bool {
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
    }

    /// Each display's menu bar. `MenuBarAgent` keeps a window per display per Space;
    /// the first one with a given frame is the one showing.
    static func displays() -> [Display] {
        guard let agent = NSRunningApplication.runningApplications(withBundleIdentifier: agentBundleID).first else { return [] }
        let element = AXUIElementCreateApplication(agent.processIdentifier)
        AXUIElementSetMessagingTimeout(element, messagingTimeout)
        let ownPID = ProcessInfo.processInfo.processIdentifier

        var seen: [CGRect] = []
        return children(of: element).compactMap { window -> Display? in
            guard let windowFrame = frame(of: window), windowFrame.width > 0, !seen.contains(windowFrame) else { return nil }
            seen.append(windowFrame)
            let slots = children(of: window).compactMap { element -> Slot? in
                // Each slot appears twice: a plain element hosting the item, and (for
                // system items) a group with the same frame. Keep the plain one.
                guard ((value(of: element, kAXRoleAttribute) as String?) ?? "").isEmpty,
                      let slotFrame = frame(of: element), slotFrame.width > 0,
                      let host = children(of: element).first else { return nil }
                var pid: pid_t = 0
                AXUIElementGetPid(host, &pid)
                return Slot(slot: MenuBarSlot(minX: slotFrame.minX, width: slotFrame.width), owner: pid, isDrawers: pid == ownPID)
            }
            return Display(frame: windowFrame, slots: slots)
        }
    }

    // MARK: - Accessibility helpers

    private static func value<T>(of element: AXUIElement, _ attribute: String) -> T? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as? T
    }

    private static func children(of element: AXUIElement) -> [AXUIElement] {
        value(of: element, kAXChildrenAttribute) ?? []
    }

    private static func frame(of element: AXUIElement) -> CGRect? {
        guard let position: AXValue = value(of: element, kAXPositionAttribute),
              let size: AXValue = value(of: element, kAXSizeAttribute) else { return nil }
        var origin = CGPoint.zero
        var extent = CGSize.zero
        guard AXValueGetValue(position, .cgPoint, &origin), AXValueGetValue(size, .cgSize, &extent) else { return nil }
        return CGRect(origin: origin, size: extent)
    }
}
