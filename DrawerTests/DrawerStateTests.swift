import XCTest

final class DrawerStateTests: XCTestCase {

    // MARK: - toggled

    func testToggledFromOpenIsClosed() {
        XCTAssertEqual(DrawerState.open.toggled, .closed)
    }

    func testToggledFromClosedIsOpen() {
        XCTAssertEqual(DrawerState.closed.toggled, .open)
    }

    // MARK: - front

    func testFrontHiddenWhileOpen() {
        XCTAssertFalse(DrawerState.open.showsFront)
    }

    func testFrontShownWhileClosed() {
        XCTAssertTrue(DrawerState.closed.showsFront)
    }

    func testClosedSymbolIsArchiveBox() {
        XCTAssertEqual(closedSymbolName, "archivebox")
    }

    // MARK: - menuActionTitle

    func testOpenMenuActionClosesDrawer() {
        XCTAssertEqual(DrawerState.open.menuActionTitle, "Close Drawer")
    }

    func testClosedMenuActionOpensDrawer() {
        XCTAssertEqual(DrawerState.closed.menuActionTitle, "Open Drawer")
    }

    // MARK: - accessibility

    func testEachPartHasADistinctLabel() {
        let labels = DrawerPart.allCases.map(accessibilityLabel(for:))
        XCTAssertEqual(Set(labels).count, DrawerPart.allCases.count)
    }

    func testPartLabels() {
        XCTAssertEqual(accessibilityLabel(for: .handle), "Drawer, left edge")
        XCTAssertEqual(accessibilityLabel(for: .wall), "Drawer, right edge")
        XCTAssertEqual(accessibilityLabel(for: .front), "Closed drawer")
    }

    func testOpenHelpDescribesClosing() {
        XCTAssertEqual(accessibilityHelp(for: .open), "Click to close the drawer.")
    }

    func testClosedHelpDescribesOpening() {
        XCTAssertEqual(accessibilityHelp(for: .closed), "Click to open the drawer.")
    }

    // MARK: - wallLength

    func testClosedWallLength() {
        XCTAssertEqual(wallLength(for: .closed), 10_000)
    }

    func testOpenWallLengthIsVariable() {
        XCTAssertEqual(wallLength(for: .open), NSStatusItem.variableLength)
    }

    // MARK: - preferred positions

    func testPreferredPositionMatchesWhatTheMenuBarSaves() {
        // Observed: a wall spanning x 2104–2127 on a 2560pt screen is saved as 433.
        XCTAssertEqual(preferredPosition(itemMaxX: 2127, screenMaxX: 2560), 433)
    }

    func testPreferredPositionOnSecondaryScreen() {
        XCTAssertEqual(preferredPosition(itemMaxX: -200, screenMaxX: 0), 200)
    }

    func testFrontSortsJustRightOfWall() {
        XCTAssertEqual(frontPreferredPosition(wallPosition: 433), 432)
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

    // MARK: - bracketRects

    private func assertOnPixelGrid(_ rects: [CGRect], scale: CGFloat, file: StaticString = #filePath, line: UInt = #line) {
        for rect in rects {
            for edge in [rect.minX, rect.maxX, rect.minY, rect.maxY] {
                let device = edge * scale
                XCTAssertEqual(device, device.rounded(), accuracy: 0.0001, "edge \(edge) at \(scale)x", file: file, line: line)
            }
        }
    }

    func testBracketEdgesOnPixelGridAt1x() {
        assertOnPixelGrid(bracketRects(opening: true, scale: 1), scale: 1)
        assertOnPixelGrid(bracketRects(opening: false, scale: 1), scale: 1)
    }

    func testBracketEdgesOnPixelGridAt2x() {
        assertOnPixelGrid(bracketRects(opening: true, scale: 2), scale: 2)
        assertOnPixelGrid(bracketRects(opening: false, scale: 2), scale: 2)
    }

    func testBracketStrokeIsOnePixelAt1xAndOnePointFiveAt2x() {
        XCTAssertEqual(bracketRects(opening: true, scale: 1)[0].width, 1)
        XCTAssertEqual(bracketRects(opening: true, scale: 2)[0].width, 1.5)
    }

    func testClosingBracketMirrorsOpeningBracket() {
        for scale: CGFloat in [1, 2] {
            let opening = bracketRects(opening: true, scale: scale)
            let closing = bracketRects(opening: false, scale: scale)
            for (o, c) in zip(opening, closing) {
                XCTAssertEqual(c.minX, bracketSize.width - o.maxX, accuracy: 0.0001)
                XCTAssertEqual(c.minY, o.minY)
                XCTAssertEqual(c.size, o.size)
            }
        }
    }

    func testBracketStaysInsideCanvas() {
        let canvas = CGRect(origin: .zero, size: bracketSize)
        for scale: CGFloat in [1, 2, 3] {
            for rect in bracketRects(opening: true, scale: scale) + bracketRects(opening: false, scale: scale) {
                XCTAssertTrue(canvas.contains(rect))
            }
        }
    }

    // MARK: - bounce

    func testBounceStartsAndEndsAtRest() {
        XCTAssertEqual(bounceScales.first, 1)
        XCTAssertEqual(bounceScales.last, 1)
    }

    func testBounceKeyTimesMatchScalesAndSpanTheDuration() {
        XCTAssertEqual(bounceKeyTimes.count, bounceScales.count)
        XCTAssertEqual(bounceKeyTimes.first, 0)
        XCTAssertEqual(bounceKeyTimes.last, 1)
        XCTAssertEqual(bounceKeyTimes, bounceKeyTimes.sorted())
    }

    func testBounceIsSubtle() {
        XCTAssertLessThan(bounceDuration, 0.5)
        for scale in bounceScales {
            XCTAssertGreaterThanOrEqual(scale, 0.8)
            XCTAssertLessThanOrEqual(scale, 1.15)
        }
    }

    // MARK: - clickAction

    func testRightClickShowsMenu() {
        XCTAssertEqual(clickAction(eventType: .rightMouseUp, modifiers: []), .showMenu)
    }

    func testControlClickShowsMenu() {
        XCTAssertEqual(clickAction(eventType: .leftMouseUp, modifiers: .control), .showMenu)
    }

    func testLeftClickToggles() {
        XCTAssertEqual(clickAction(eventType: .leftMouseUp, modifiers: []), .toggle)
    }

    func testPressWithoutEventToggles() {
        XCTAssertEqual(clickAction(eventType: nil, modifiers: []), .toggle)
    }

    func testKeyboardPressToggles() {
        XCTAssertEqual(clickAction(eventType: .keyDown, modifiers: []), .toggle)
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
