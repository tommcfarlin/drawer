import AppKit

/// Whether the drawer is open (its icons showing) or closed (its icons hidden).
enum DrawerState: String {
    case open
    case closed

    var toggled: DrawerState { self == .open ? .closed : .open }

    /// The front (the shut drawer) only exists while closed.
    var showsFront: Bool { self == .closed }

    /// The menu command for what clicking the drawer will do next.
    var menuActionTitle: String {
        self == .open ? String(localized: "Close Drawer") : String(localized: "Open Drawer")
    }
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
    case .handle: return String(localized: "Drawer, left edge")
    case .wall: return String(localized: "Drawer, right edge")
    case .front: return String(localized: "Closed drawer")
    }
}

/// What activating any part will do next.
func accessibilityHelp(for state: DrawerState) -> String {
    state == .open
        ? String(localized: "Click to close the drawer.")
        : String(localized: "Click to open the drawer.")
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

/// At launch, before anything can be measured, the front's position comes from the
/// wall's saved one, if there is one.
func seededFrontPosition(savedWallPosition: Double?) -> Double? {
    savedWallPosition.map { Double(frontPreferredPosition(wallPosition: CGFloat($0))) }
}

// MARK: - Bounce

/// How long the drawer icon's bounce lasts after opening or closing.
let bounceDuration: TimeInterval = 0.35

/// Scale keyframes for the `]` bounce: a quick squash, a small overshoot, then rest,
/// approximating SF Symbols' bounce (which only works on symbol images).
let bounceScales: [CGFloat] = [1, 0.82, 1.1, 1]
let bounceKeyTimes: [Double] = [0, 0.3, 0.7, 1]

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

/// A user asking for the state the drawer is already in (for example, opening Drawer
/// again while it's open) changes nothing. Launch restores always apply, because the
/// items start in a provisional layout.
func isNoOp(current: DrawerState, requested: DrawerState, userInitiated: Bool) -> Bool {
    userInitiated && current == requested
}

/// Default for first launch (or an unrecognized saved value) is open.
func restoredState(from rawValue: String?) -> DrawerState {
    rawValue.flatMap(DrawerState.init(rawValue:)) ?? .open
}

// MARK: - Notch

/// A status item window on one display, as the window list reports it.
struct MenuBarWindow: Equatable {
    let minX: CGFloat
    let width: CGFloat
    let isOnScreen: Bool
}

/// How the notch affects the drawer on one display.
enum NotchFit: Equatable {
    /// Nothing of Drawer's is hidden (or there's nothing to say).
    case allFit
    /// The handle and some drawer icons are hidden; `visible` drawer icons still fit.
    case drawerPartlyHidden(visible: Int)
    /// Even the drawer's right edge (or, when closed, the archive box) is hidden.
    case outsideDoesNotFit
}

/// Each display's copy of the menu bar may place an item up to about 2pt differently.
let notchTolerance: CGFloat = 3

/// Items sit the same distance from the right edge on every display's menu bar copy.
func offsetFromRightEdge(itemMinX: CGFloat, screenMaxX: CGFloat) -> CGFloat {
    screenMaxX - itemMinX
}

func minX(atOffsetFromRightEdge offset: CGFloat, screenMaxX: CGFloat) -> CGFloat {
    screenMaxX - offset
}

/// Measures the drawer against one notched display's status item windows. The menu bar
/// hides overflow from the left, so what's visible is always a rightmost run: if the
/// handle is hidden, every on-screen window left of the wall is a drawer icon.
///
/// - Parameters:
///   - handleMinX: where `[` sits on this display, or nil when the drawer is closed.
///   - wallMinX: where `]` sits on this display, or the archive box when closed.
func notchFit(items: [MenuBarWindow], handleMinX: CGFloat?, wallMinX: CGFloat?, tolerance: CGFloat = notchTolerance) -> NotchFit {
    guard let wallMinX else { return .allFit }
    let onScreen = items.filter(\.isOnScreen)
    func isShowing(_ x: CGFloat) -> Bool { onScreen.contains { abs($0.minX - x) <= tolerance } }

    guard isShowing(wallMinX) else { return .outsideDoesNotFit }
    guard let handleMinX, !isShowing(handleMinX) else { return .allFit }
    return .drawerPartlyHidden(visible: onScreen.filter { $0.minX < wallMinX - tolerance }.count)
}

/// The most serious of several displays' results.
func worst(_ fits: [NotchFit]) -> NotchFit {
    if fits.contains(.outsideDoesNotFit) { return .outsideDoesNotFit }
    let partly = fits.compactMap { fit -> Int? in
        if case let .drawerPartlyHidden(visible) = fit { return visible }
        return nil
    }
    return partly.min().map { .drawerPartlyHidden(visible: $0) } ?? .allFit
}

/// Dimmed lines for Drawer's menu (and, first line only, the tooltip) explaining what
/// the notch is hiding. Empty when there's nothing to say. While the drawer is closed,
/// the partly-hidden hint describes the open drawer (from the last measurement).
func notchHint(for fit: NotchFit, drawerIsOpen: Bool = true) -> [String] {
    switch fit {
    case .allFit:
        return []
    case let .drawerPartlyHidden(visible):
        if drawerIsOpen {
            let count: String
            switch visible {
            case 0: count = String(localized: "No Drawer Icons Fit Beside the Notch")
            case 1: count = String(localized: "Only the Icon Nearest ] Fits Beside the Notch")
            default: count = String(localized: "Only the \(visible) Icons Nearest ] Fit Beside the Notch")
            }
            return [count, String(localized: "⌘-Drag Your Favorites Next to ]")]
        }
        let count: String
        switch visible {
        case 0: count = String(localized: "When Open, No Drawer Icons Fit Beside the Notch")
        case 1: count = String(localized: "When Open, Only the Icon Nearest ] Fits Beside the Notch")
        default: count = String(localized: "When Open, Only the \(visible) Icons Nearest ] Fit Beside the Notch")
        }
        return [count, String(localized: "Open the Drawer and ⌘-Drag Your Favorites Next to ]")]
    case .outsideDoesNotFit:
        return [
            String(localized: "Too Many Icons Outside the Drawer to Fit Beside the Notch"),
            String(localized: "⌘-Drag Some Icons Into the Drawer"),
        ]
    }
}

/// Which notch result to explain. Only when a notched display is present. The
/// outside-doesn't-fit warning always wins; otherwise an open drawer uses the current
/// measurement and a closed one uses the last measurement taken while open (a closed
/// drawer's icons are off-screen, so they can't be measured). `current` is nil when
/// Drawer's items haven't been laid out yet; then the last open measurement stands in.
func notchFitToExplain(hasNotch: Bool, state: DrawerState, current: NotchFit?, lastOpen: NotchFit?) -> NotchFit {
    guard hasNotch else { return .allFit }
    if current == .outsideDoesNotFit { return .outsideDoesNotFit }
    if state == .open, let current { return current }
    return lastOpen ?? .allFit
}
