import AppKit

/// Whether the drawer is open (its icons showing) or closed (its icons hidden).
enum DrawerState: String {
    case open
    case closed

    var toggled: DrawerState { self == .open ? .closed : .open }

    /// The front (the shut drawer) only exists while closed.
    var showsFront: Bool { self == .closed }

    /// What clicking the drawer will do next.
    var accessibilityLabel: String { self == .open ? "Close drawer" : "Open drawer" }
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

/// Default for first launch (or an unrecognized saved value) is open.
func restoredState(from rawValue: String?) -> DrawerState {
    rawValue.flatMap(DrawerState.init(rawValue:)) ?? .open
}
