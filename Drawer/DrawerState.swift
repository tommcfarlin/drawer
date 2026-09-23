import AppKit

/// Whether the drawer is open (its icons showing) or closed (its icons hidden).
enum DrawerState: String {
    case open
    case closed

    var toggled: DrawerState { self == .open ? .closed : .open }

    /// The front (the shut drawer) only exists while closed.
    var showsFront: Bool { self == .closed }

    /// The menu command for what clicking the drawer will do next.
    var menuActionTitle: String { self == .open ? "Close Drawer" : "Open Drawer" }
}

/// Drawer's three menu bar items.
enum DrawerPart: CaseIterable {
    case handle
    case wall
    case front
}

/// Each part gets its own VoiceOver name, so the two brackets don't sound identical.
func accessibilityLabel(for part: DrawerPart) -> String {
    switch part {
    case .handle: return "Drawer, left edge"
    case .wall: return "Drawer, right edge"
    case .front: return "Closed drawer"
    }
}

/// What activating any part will do next.
func accessibilityHelp(for state: DrawerState) -> String {
    state == .open ? "Click to close the drawer." : "Click to open the drawer."
}

/// The bracket images' size in points.
let bracketSize = CGSize(width: 7, height: 16)

/// The filled rectangles that make up `[` (or `]` when `opening` is false), in points,
/// with every edge on a whole device pixel at the given backing scale so the strokes
/// stay crisp on non-Retina displays. The stroke is 1.5pt on Retina (3px) and 1px at 1x,
/// where 1.5px would be smoothed across two pixels.
func bracketRects(opening: Bool, scale: CGFloat) -> [CGRect] {
    let px = { (points: CGFloat) in (points * scale).rounded() }
    let width = px(bracketSize.width)
    let height = px(bracketSize.height)
    let stroke = max(1, (1.5 * scale - 0.25).rounded())
    let inset = px(1)
    let armEnd = px(6)

    // Built for `[` in device pixels, then mirrored for `]`.
    var rects = [
        CGRect(x: inset, y: inset, width: stroke, height: height - 2 * inset),           // spine
        CGRect(x: inset, y: height - inset - stroke, width: armEnd - inset, height: stroke), // top arm
        CGRect(x: inset, y: inset, width: armEnd - inset, height: stroke),               // bottom arm
    ]
    if !opening {
        rects = rects.map { CGRect(x: width - $0.maxX, y: $0.minY, width: $0.width, height: $0.height) }
    }
    return rects.map {
        CGRect(x: $0.minX / scale, y: $0.minY / scale, width: $0.width / scale, height: $0.height / scale)
    }
}

/// SF Symbol shown by the front while the drawer is closed.
let closedSymbolName = "archivebox"

/// Wide enough to push the wall, the handle, and everything between them off any display.
/// macOS moves an item this wide entirely off-screen, which is why the shut drawer
/// is drawn by a separate front item.
let wallClosedLength: CGFloat = 10_000

func wallLength(for state: DrawerState) -> CGFloat {
    state == .closed ? wallClosedLength : NSStatusItem.variableLength
}

/// The menu bar orders items by a saved "preferred position": the distance from the
/// screen's right edge to the item's right edge, larger meaning further left.
func preferredPosition(itemMaxX: CGFloat, screenMaxX: CGFloat) -> CGFloat {
    screenMaxX - itemMaxX
}

/// Just under the wall's preferred position puts the front immediately right of it.
func frontPreferredPosition(wallPosition: CGFloat) -> CGFloat {
    wallPosition - 1
}

/// Closing only makes sense when the handle is left of the wall.
/// If either position is unknown, don't close.
func canClose(handleMinX: CGFloat?, wallMinX: CGFloat?) -> Bool {
    guard let h = handleMinX, let w = wallMinX else { return false }
    return h < w
}

/// Whether a status item's window has a real on-screen position yet.
/// While the menu bar is still laying out, frames can be empty or off every screen.
func isPlaced(_ frame: CGRect, on screens: [CGRect]) -> Bool {
    guard frame.width > 0, frame.height > 0 else { return false }
    return screens.contains { $0.contains(frame) }
}

/// What a press on a drawer item should do.
enum ClickAction: Equatable {
    case toggle
    case showMenu
}

/// Only a right-click, or a Control-click, shows the menu. Anything else, including
/// a press from VoiceOver or the keyboard that has no mouse event, toggles the drawer.
func clickAction(eventType: NSEvent.EventType?, modifiers: NSEvent.ModifierFlags) -> ClickAction {
    switch eventType {
    case .rightMouseUp:
        return .showMenu
    case .leftMouseUp where modifiers.contains(.control):
        return .showMenu
    default:
        return .toggle
    }
}

/// Default for first launch (or an unrecognized saved value) is open.
func restoredState(from rawValue: String?) -> DrawerState {
    rawValue.flatMap(DrawerState.init(rawValue:)) ?? .open
}
