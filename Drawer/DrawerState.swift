import AppKit

/// Whether the icons left of the divider are showing or tucked away.
enum DrawerState: String {
    case expanded
    case collapsed

    var toggled: DrawerState { self == .expanded ? .collapsed : .expanded }

    /// SF Symbol for the toggle; points the direction the next click moves icons.
    var toggleSymbolName: String { self == .expanded ? "chevron.right" : "chevron.left" }

    var accessibilityLabel: String {
        self == .expanded ? "Collapse menu bar icons" : "Expand menu bar icons"
    }
}

/// Wide enough to push every item left of the divider off any display.
let dividerCollapsedLength: CGFloat = 10_000

func dividerLength(for state: DrawerState) -> CGFloat {
    state == .collapsed ? dividerCollapsedLength : NSStatusItem.variableLength
}

/// Collapsing is only safe when the divider is left of the toggle.
/// If either position is unknown, don't collapse.
func canCollapse(dividerMinX: CGFloat?, toggleMinX: CGFloat?) -> Bool {
    guard let d = dividerMinX, let t = toggleMinX else { return false }
    return d < t
}

/// Whether a status item's window has a real on-screen position yet.
/// While the menu bar is still laying out, frames can be empty or off every screen.
func isPlaced(_ frame: CGRect, on screens: [CGRect]) -> Bool {
    guard frame.width > 0, frame.height > 0 else { return false }
    return screens.contains { $0.contains(frame) }
}

/// Default for first launch is expanded.
func restoredState(from rawValue: String?) -> DrawerState {
    rawValue.flatMap(DrawerState.init(rawValue:)) ?? .expanded
}
