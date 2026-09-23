import AppKit

/// Reads each notched display's status item windows from the window list. This needs
/// no permissions: it uses only positions, widths, and whether each window is on
/// screen, never window names or contents.
enum MenuBarWindows {
    /// A notched display's right edge and its status item windows.
    struct NotchedDisplay {
        let screenMaxX: CGFloat
        let windows: [MenuBarWindow]
    }

    /// The window list's layer for menu bar status items.
    private static let statusItemLayer = 25
    /// Wider layer-25 windows are menu bar backdrops, not items.
    private static let maxItemWidth: CGFloat = 300

    /// Identifies the current set of notched displays and their sizes, so a remembered
    /// measurement is only reused on the same setup.
    static func notchedDisplaySignature() -> String {
        NSScreen.screens
            .filter { $0.auxiliaryTopRightArea != nil }
            .compactMap { screen -> String? in
                guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
                      let right = screen.auxiliaryTopRightArea else { return nil }
                return "\(id):\(Int(screen.frame.width))x\(Int(screen.frame.height)):\(Int(right.width))"
            }
            .sorted()
            .joined(separator: ",")
    }

    static func notchedDisplays() -> [NotchedDisplay] {
        let notched = NSScreen.screens.filter { $0.auxiliaryTopRightArea != nil }
        guard !notched.isEmpty,
              let info = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]]
        else { return [] }

        let windows: [(frame: CGRect, isOnScreen: Bool)] = info.compactMap { window in
            guard (window[kCGWindowLayer as String] as? Int) == statusItemLayer,
                  let bounds = window[kCGWindowBounds as String] as? NSDictionary,
                  let frame = CGRect(dictionaryRepresentation: bounds),
                  frame.width > 0, frame.width < maxItemWidth
            else { return nil }
            return (frame, (window[kCGWindowIsOnscreen as String] as? Bool) ?? false)
        }

        return notched.compactMap { screen in
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { return nil }
            // Window-list frames use the same x as AppKit, with y measured from the top.
            let bounds = CGDisplayBounds(id)
            let items = windows
                .filter { bounds.contains(CGPoint(x: $0.frame.midX, y: $0.frame.midY)) }
                .map { MenuBarWindow(minX: $0.frame.minX, width: $0.frame.width, isOnScreen: $0.isOnScreen) }
            return NotchedDisplay(screenMaxX: screen.frame.maxX, windows: items)
        }
    }
}
