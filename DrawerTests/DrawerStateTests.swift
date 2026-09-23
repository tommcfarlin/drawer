import XCTest

final class DrawerStateTests: XCTestCase {

    // MARK: - toggled

    func testToggledFromOpenIsClosed() {
        XCTAssertEqual(DrawerState.open.toggled, .closed)
    }

    func testToggledFromClosedIsOpen() {
        XCTAssertEqual(DrawerState.closed.toggled, .open)
    }

    // MARK: - titles

    func testHandleTitle() {
        XCTAssertEqual(handleTitle, "[")
    }

    func testOpenWallTitle() {
        XCTAssertEqual(DrawerState.open.wallTitle, "|")
    }

    func testClosedWallTitleIsEmpty() {
        XCTAssertEqual(DrawerState.closed.wallTitle, "")
    }

    func testOpenFrontTitleIsEmpty() {
        XCTAssertEqual(DrawerState.open.frontTitle, "")
    }

    func testClosedFrontTitleShowsShutDrawer() {
        XCTAssertEqual(DrawerState.closed.frontTitle, "[|")
    }

    // MARK: - accessibilityLabel

    func testOpenAccessibilityLabel() {
        XCTAssertEqual(DrawerState.open.accessibilityLabel, "Close drawer")
    }

    func testClosedAccessibilityLabel() {
        XCTAssertEqual(DrawerState.closed.accessibilityLabel, "Open drawer")
    }

    // MARK: - wallLength

    func testClosedWallLength() {
        XCTAssertEqual(wallLength(for: .closed), 10_000)
    }

    func testOpenWallLengthIsVariable() {
        XCTAssertEqual(wallLength(for: .open), NSStatusItem.variableLength)
    }

    // MARK: - frontLength

    func testOpenFrontLengthIsZero() {
        XCTAssertEqual(frontLength(for: .open), 0)
    }

    func testClosedFrontLengthIsVariable() {
        XCTAssertEqual(frontLength(for: .closed), NSStatusItem.variableLength)
    }

    // MARK: - canClose

    func testCanCloseWhenHandleIsLeftOfWall() {
        XCTAssertTrue(canClose(handleMinX: 100, wallMinX: 200))
    }

    func testCannotCloseWhenHandleIsRightOfWall() {
        XCTAssertFalse(canClose(handleMinX: 300, wallMinX: 200))
    }

    func testCannotCloseWhenPositionsAreEqual() {
        XCTAssertFalse(canClose(handleMinX: 200, wallMinX: 200))
    }

    func testCannotCloseWhenHandlePositionIsUnknown() {
        XCTAssertFalse(canClose(handleMinX: nil, wallMinX: 200))
    }

    func testCannotCloseWhenWallPositionIsUnknown() {
        XCTAssertFalse(canClose(handleMinX: 100, wallMinX: nil))
    }

    func testCannotCloseWhenBothPositionsAreUnknown() {
        XCTAssertFalse(canClose(handleMinX: nil, wallMinX: nil))
    }

    // MARK: - restoredState

    func testRestoredStateDefaultsToOpenWhenMissing() {
        XCTAssertEqual(restoredState(from: nil), .open)
    }

    func testRestoredStateDefaultsToOpenForUnknownValue() {
        XCTAssertEqual(restoredState(from: "bogus"), .open)
    }

    func testRestoredStateDefaultsToOpenForOldDesignValue() {
        XCTAssertEqual(restoredState(from: "collapsed"), .open)
    }

    func testRestoredStateRoundTripsOpen() {
        XCTAssertEqual(restoredState(from: DrawerState.open.rawValue), .open)
    }

    func testRestoredStateRoundTripsClosed() {
        XCTAssertEqual(restoredState(from: DrawerState.closed.rawValue), .closed)
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
