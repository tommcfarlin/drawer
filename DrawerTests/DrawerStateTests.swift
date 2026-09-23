import XCTest

final class DrawerStateTests: XCTestCase {

    // MARK: - toggled

    func testToggledFromExpandedIsCollapsed() {
        XCTAssertEqual(DrawerState.expanded.toggled, .collapsed)
    }

    func testToggledFromCollapsedIsExpanded() {
        XCTAssertEqual(DrawerState.collapsed.toggled, .expanded)
    }

    // MARK: - toggleSymbolName

    func testExpandedSymbolPointsRight() {
        XCTAssertEqual(DrawerState.expanded.toggleSymbolName, "chevron.right")
    }

    func testCollapsedSymbolPointsLeft() {
        XCTAssertEqual(DrawerState.collapsed.toggleSymbolName, "chevron.left")
    }

    // MARK: - accessibilityLabel

    func testExpandedAccessibilityLabel() {
        XCTAssertEqual(DrawerState.expanded.accessibilityLabel, "Collapse menu bar icons")
    }

    func testCollapsedAccessibilityLabel() {
        XCTAssertEqual(DrawerState.collapsed.accessibilityLabel, "Expand menu bar icons")
    }

    // MARK: - dividerLength

    func testCollapsedDividerLength() {
        XCTAssertEqual(dividerLength(for: .collapsed), 10_000)
    }

    func testExpandedDividerLengthIsVariable() {
        XCTAssertEqual(dividerLength(for: .expanded), NSStatusItem.variableLength)
    }

    // MARK: - canCollapse

    func testCanCollapseWhenDividerIsLeftOfToggle() {
        XCTAssertTrue(canCollapse(dividerMinX: 100, toggleMinX: 200))
    }

    func testCannotCollapseWhenDividerIsRightOfToggle() {
        XCTAssertFalse(canCollapse(dividerMinX: 300, toggleMinX: 200))
    }

    func testCannotCollapseWhenPositionsAreEqual() {
        XCTAssertFalse(canCollapse(dividerMinX: 200, toggleMinX: 200))
    }

    func testCannotCollapseWhenDividerPositionIsUnknown() {
        XCTAssertFalse(canCollapse(dividerMinX: nil, toggleMinX: 200))
    }

    func testCannotCollapseWhenTogglePositionIsUnknown() {
        XCTAssertFalse(canCollapse(dividerMinX: 100, toggleMinX: nil))
    }

    func testCannotCollapseWhenBothPositionsAreUnknown() {
        XCTAssertFalse(canCollapse(dividerMinX: nil, toggleMinX: nil))
    }

    // MARK: - restoredState

    func testRestoredStateDefaultsToExpandedWhenMissing() {
        XCTAssertEqual(restoredState(from: nil), .expanded)
    }

    func testRestoredStateDefaultsToExpandedForUnknownValue() {
        XCTAssertEqual(restoredState(from: "bogus"), .expanded)
    }

    func testRestoredStateRoundTripsExpanded() {
        XCTAssertEqual(restoredState(from: DrawerState.expanded.rawValue), .expanded)
    }

    func testRestoredStateRoundTripsCollapsed() {
        XCTAssertEqual(restoredState(from: DrawerState.collapsed.rawValue), .collapsed)
    }

    // MARK: - isPlaced

    private let screens = [
        CGRect(x: 0, y: 0, width: 2560, height: 1440),
        CGRect(x: -1512, y: 0, width: 1512, height: 982),
    ]

    func testPlacedWhenInsideMainScreen() {
        XCTAssertTrue(isPlaced(CGRect(x: 1410, y: 1410, width: 24, height: 30), on: screens))
    }

    func testPlacedWhenInsideSecondaryScreen() {
        XCTAssertTrue(isPlaced(CGRect(x: -757, y: 952, width: 32, height: 30), on: screens))
    }

    func testNotPlacedWhenHeightIsZero() {
        XCTAssertFalse(isPlaced(CGRect(x: 0, y: 0, width: 24, height: 0), on: screens))
    }

    func testNotPlacedWhenBelowEveryScreen() {
        XCTAssertFalse(isPlaced(CGRect(x: 0, y: -30, width: 24, height: 30), on: screens))
    }

    func testNotPlacedWhenOffTheRightEdge() {
        XCTAssertFalse(isPlaced(CGRect(x: 2550, y: 1410, width: 24, height: 30), on: screens))
    }

    func testNotPlacedWithNoScreens() {
        XCTAssertFalse(isPlaced(CGRect(x: 1410, y: 1410, width: 24, height: 30), on: []))
    }
}
