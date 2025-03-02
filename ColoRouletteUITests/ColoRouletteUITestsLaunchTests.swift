//
//  ColoRouletteUITestsLaunchTests.swift
//  ColoRouletteUITests
//
//  Created by Greg Turek on 3/2/25.
//

import XCTest

final class ColoRouletteUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let gameStateText = app.staticTexts["GameStateText"]
        XCTAssertTrue(gameStateText.waitForExistence(timeout: 3))
        XCTAssertEqual(gameStateText.label, "Spin to play!")
        
        let levelText = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^\\d+$")).firstMatch
        XCTAssertTrue(levelText.waitForExistence(timeout: 3))
        XCTAssertEqual(levelText.label, "1")
        
        let pointsText = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^\\d+$")).allElementsBoundByIndex
        XCTAssertTrue(pointsText.count >= 2)
        XCTAssertEqual(pointsText[1].label, "0")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Initial Game State"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
