//
//  ColoRouletteUITests.swift
//  ColoRouletteUITests
//
//  Created by Greg Turek on 3/2/25.
//

import XCTest

final class ColoRouletteUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        var launchArguments = ["--uitesting"]
        
        if self.name.contains("testLastLevelWin") || self.name.contains("testLastLevelLose") {
            launchArguments.append("--uitesting-last-level")
        }
        
        app.launchArguments = launchArguments
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Helper Methods
    
    func spinWheelAndWaitForChoosingState() throws {
        let spinButton = app.buttons["SpinButton"]
        XCTAssertTrue(spinButton.waitForExistence(timeout: 3), "Spin button should exist")
        spinButton.tap()
        
        let gameStateText = app.staticTexts["GameStateText"]
        XCTAssertTrue(gameStateText.waitForExistence(timeout: 3), "Game state text should exist")
        
        let choosingExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", "Best contrast"),
            object: gameStateText
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [choosingExpectation], timeout: 6),
            .completed,
            "Should enter choosing state"
        )
    }
    
    func verifyAndGetLevelNumbers() throws -> (current: Int, total: Int) {
        let currentLevelText = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^\\d+$")).firstMatch
        let totalLevelText = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^/\\d+$")).firstMatch
        
        XCTAssertTrue(currentLevelText.waitForExistence(timeout: 5), "Current level text should exist")
        XCTAssertTrue(totalLevelText.waitForExistence(timeout: 5), "Total level text should exist")
        
        let currentLevelString = currentLevelText.label
        let totalLevelString = totalLevelText.label.replacingOccurrences(of: "/", with: "")
        
        guard let currentLevel = Int(currentLevelString),
              let totalLevels = Int(totalLevelString) else {
            throw XCTSkip("Could not parse level numbers")
        }
        
        return (currentLevel, totalLevels)
    }
    
    func makeWrongChoiceAndVerifyLostState() throws {
        let correctButton = app.buttons["CorrectChoiceButton"]
        XCTAssertTrue(correctButton.waitForExistence(timeout: 2), "Correct choice button should exist")
        
        let allButtons = app.buttons.allElementsBoundByIndex
        let wrongButtons = allButtons.filter { button in
            return button.identifier != "CorrectChoiceButton" &&
                   (button.identifier == "WhiteButton" || button.identifier == "BlackButton")
        }
        
        XCTAssertFalse(wrongButtons.isEmpty, "Should find at least one wrong button")
        if !wrongButtons.isEmpty {
            wrongButtons[0].tap()
        }
        
        try verifyGameState(contains: "You lost", timeout: 5)
        
        XCTAssertTrue(app.buttons["NewGameButton"].exists, "New Game button should exist")
        XCTAssertFalse(app.buttons["SpinButton"].isHittable, "Spin button should not be hittable")
    }
    
    func makeCorrectChoice() throws {
        let correctButton = app.buttons["CorrectChoiceButton"]
        XCTAssertTrue(correctButton.waitForExistence(timeout: 2), "Correct choice button should exist")
        correctButton.tap()
    }
    
    func verifyGameState(contains text: String, timeout: TimeInterval = 3) throws {
        let gameStateText = app.staticTexts["GameStateText"]
        XCTAssertTrue(gameStateText.waitForExistence(timeout: 3), "Game state text should exist")
        
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", text),
            object: gameStateText
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: timeout),
            .completed,
            "Game state should contain '\(text)'"
        )
    }
    
    func startNewGameAndVerifyLevel1() throws {
        app.buttons["NewGameButton"].tap()
        
        let newLevelText = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^\\d+$")).firstMatch
        XCTAssertTrue(newLevelText.waitForExistence(timeout: 5), "New level text should exist")
        
        let newLevelString = newLevelText.label
        guard let newLevel = Int(newLevelString) else {
            throw XCTSkip("Could not parse new level number")
        }
        
        XCTAssertEqual(newLevel, 1, "Should be back at level 1 after new game")
    }
    
    // MARK: - Test Methods
    
    @MainActor
    func testGameFlow() throws {
        enum TestScenario {
            case noChoice
            case wrongChoice
            case rightChoiceWithSpin
            case rightChoiceWithCashOut
        }
        
        var completedScenarios: Set<TestScenario> = []
        
        while completedScenarios.count < 4 {
            try spinWheelAndWaitForChoosingState()
            
            if !completedScenarios.contains(.noChoice) {
                let timerText = app.staticTexts["ChoiceTimer"]
                XCTAssertTrue(timerText.waitForExistence(timeout: 2), "Timer text should exist")
                
                let timerValue = timerText.label.replacingOccurrences(of: "$", with: "")
                guard let initialTimerValue = Int(timerValue) else {
                    XCTFail("Could not parse timer value from: \(timerText.label)")
                    continue
                }
                
                let timeoutDuration = Double(initialTimerValue) + 2.0
                
                do {
                    try verifyGameState(contains: "You lost", timeout: timeoutDuration)
                    XCTAssertTrue(app.buttons["NewGameButton"].exists, "New Game button should exist")
                    XCTAssertFalse(app.buttons["SpinButton"].isHittable, "Spin button should not be hittable")
                    completedScenarios.insert(.noChoice)
                    app.buttons["NewGameButton"].tap()
                    continue
                } catch {
                    XCTFail("Timer did not expire or game did not transition to lost state after \(timeoutDuration) seconds")
                }
            }
            else if !completedScenarios.contains(.wrongChoice) {
                try makeWrongChoiceAndVerifyLostState()
                completedScenarios.insert(.wrongChoice)
                app.buttons["NewGameButton"].tap()
                continue
            } else {
                try makeCorrectChoice()
                
                try verifyGameState(contains: "Spin or cash out")
                
                if !completedScenarios.contains(.rightChoiceWithSpin) {
                    XCTAssertTrue(app.buttons["SpinButton"].isHittable, "Spin button should be hittable")
                    app.buttons["SpinButton"].tap()
                    completedScenarios.insert(.rightChoiceWithSpin)
                    continue
                }
                
                if !completedScenarios.contains(.rightChoiceWithCashOut) {
                    XCTAssertTrue(app.buttons["CashOutButton"].exists, "Cash Out button should exist")
                    app.buttons["CashOutButton"].tap()
                    
                    try verifyGameState(contains: "You won")
                    
                    XCTAssertTrue(app.buttons["NewGameButton"].exists, "New Game button should exist")
                    app.buttons["NewGameButton"].tap()
                    completedScenarios.insert(.rightChoiceWithCashOut)
                }
            }
        }
        
        XCTAssertTrue(completedScenarios.contains(.noChoice), "No choice scenario should be completed")
        XCTAssertTrue(completedScenarios.contains(.wrongChoice), "Wrong choice scenario should be completed")
        XCTAssertTrue(completedScenarios.contains(.rightChoiceWithSpin), "Right choice with spin scenario should be completed")
        XCTAssertTrue(completedScenarios.contains(.rightChoiceWithCashOut), "Right choice with cash out scenario should be completed")
    }
    
    @MainActor
    func testLastLevelWin() throws {
        let levels = try verifyAndGetLevelNumbers()
        XCTAssertEqual(levels.current, levels.total, "Should be at the last level")
        
        try spinWheelAndWaitForChoosingState()
        
        try makeCorrectChoice()
        
        try verifyGameState(contains: "You won", timeout: 5)
        
        try startNewGameAndVerifyLevel1()
    }
    
    @MainActor
    func testLastLevelLose() throws {
        let levels = try verifyAndGetLevelNumbers()
        XCTAssertEqual(levels.current, levels.total, "Should be at the last level")
        
        try spinWheelAndWaitForChoosingState()
        
        try makeWrongChoiceAndVerifyLostState()
        
        try startNewGameAndVerifyLevel1()
        
        let pointsText = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^\\d+$")).allElementsBoundByIndex
        XCTAssertTrue(pointsText.count >= 2, "Should find at least two numeric text elements")
        
        if pointsText.count >= 2 {
            let pointsString = pointsText[1].label
            guard let points = Int(pointsString) else {
                XCTFail("Could not parse points")
                return
            }
            
            XCTAssertEqual(points, 0, "Points should be reset to 0 after losing")
        }
    }
}
