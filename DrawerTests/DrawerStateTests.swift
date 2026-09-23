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
}
