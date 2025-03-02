//
//  ColoRouletteTests.swift
//  ColoRouletteTests
//
//  Created by Greg Turek on 3/2/25.
//

import Testing
import SwiftUI
import ColorPerception
@testable import ColoRoulette

@MainActor
struct ColoRouletteTests {
    @Test("Initial state is properly configured")
    func initialState() async throws {
        let viewModel = ContentViewModel()
        
        #expect(viewModel.viewState.gameState == .initial)
        #expect(viewModel.viewState.status.level == 1)
        #expect(viewModel.viewState.status.levels >= viewModel.viewState.status.level)
        #expect(viewModel.viewState.status.points == 0)
        #expect(viewModel.viewState.spinnableWheel.wedgeColors.contains(viewModel.viewState.spinnableWheel.selectedColor))
    }
    
    @Test("Spin animation completion transitions to choosing state")
    func spinAnimationCompletion() async throws {
        let viewModel = ContentViewModel()
        
        await viewModel.handle(.spin)
        
        #expect(viewModel.viewState.gameState == .choosing)
    }
    
    @Test("Correct contrast choice increases points")
    func correctContrastChoice() async throws {
        let viewModel = ContentViewModel()
        
        await viewModel.handle(.spin)
        viewModel.viewState.updateGameState(to: .choosing) {}
        
        let selectedColor = viewModel.viewState.spinnableWheel.selectedColor
        let bestContrast = selectedColor.perceptualContrastingColor() == .black ? ContrastChoice.dark : ContrastChoice.light
        let initialPoints = viewModel.viewState.status.points
        
        await viewModel.handle(.choose(contrast: bestContrast))
        
        #expect(viewModel.viewState.status.points > initialPoints)
        #expect(viewModel.viewState.gameState == .correct || viewModel.viewState.gameState == .won)
    }
    
    @Test("Incorrect contrast choice resets points")
    func incorrectContrastChoice() async throws {
        let viewModel = ContentViewModel()
        
        await viewModel.handle(.spin)
        viewModel.viewState.updateGameState(to: .choosing) {}
        
        let selectedColor = viewModel.viewState.spinnableWheel.selectedColor
        let worstContrast = selectedColor.perceptualContrastingColor() == .black ? ContrastChoice.light : ContrastChoice.dark
        
        viewModel.viewState.status.points = 10
        
        await viewModel.handle(.choose(contrast: worstContrast))
        
        #expect(viewModel.viewState.status.points == 0)
        #expect(viewModel.viewState.gameState == .lost)
    }
    
    @Test("Choice timer counts down and expires to cause loss")
    func choiceTimerExpiration() async throws {
        let viewModel = ContentViewModel()
        
        await viewModel.handle(.spin)
        viewModel.viewState.updateGameState(to: .choosing) {}
        
        #expect(viewModel.viewState.spinnableWheel.choiceTimeLeft == 10)
        
        try await Task.sleep(for: .seconds(1.5))
        
        #expect(viewModel.viewState.spinnableWheel.choiceTimeLeft < 10)
        
        viewModel.viewState.spinnableWheel.choiceTimeLeft = 1
        try await Task.sleep(for: .seconds(1.5))
        
        #expect(viewModel.viewState.gameState == .lost)
    }
    
    @Test("Cash out updates game state to won")
    func cashOut() async throws {
        let viewModel = ContentViewModel()
        
        viewModel.viewState.updateGameState(to: .correct) {}
        await viewModel.handle(.cashOut)
        
        #expect(viewModel.viewState.gameState == .won)
    }
    
    @Test("Start new game resets state")
    func startNewGame() async throws {
        let viewModel = ContentViewModel()
        viewModel.viewState.updateGameState(to: .won) {}
        viewModel.viewState.status.level = 5
        viewModel.viewState.status.points = 100
        
        await viewModel.handle(.startNewGame)
        
        #expect(viewModel.viewState.gameState == .initial)
        #expect(viewModel.viewState.status.level == 1)
        #expect(viewModel.viewState.status.points == 0)
        #expect(viewModel.viewState.spinnableWheel.wedgeColors.contains(viewModel.viewState.spinnableWheel.selectedColor))
    }
    
    @Test("Level progression works correctly")
    func levelProgression() async throws {
        let viewModel = ContentViewModel()
        let initialLevel = viewModel.viewState.status.level
        
        await viewModel.handle(.spin)
        viewModel.viewState.updateGameState(to: .choosing) {}
        
        let selectedColor = viewModel.viewState.spinnableWheel.selectedColor
        let bestContrast = selectedColor.perceptualContrastingColor() == .black ? ContrastChoice.dark : ContrastChoice.light
        
        await viewModel.handle(.choose(contrast: bestContrast))
        await viewModel.handle(.spin)
        
        #expect(viewModel.viewState.status.level == initialLevel + 1)
    }
    
    @Test("Handles maximum level correctly")
    func maximumLevel() async throws {
        let viewModel = ContentViewModel()
        let maxLevel = viewModel.viewState.status.levels
        viewModel.viewState.status.level = maxLevel
        
        await viewModel.handle(.spin)
        viewModel.viewState.updateGameState(to: .choosing) {}
        
        let selectedColor = viewModel.viewState.spinnableWheel.selectedColor
        let bestContrast = selectedColor.perceptualContrastingColor() == .black ? ContrastChoice.dark : ContrastChoice.light
        
        await viewModel.handle(.choose(contrast: bestContrast))
        
        #expect(viewModel.viewState.gameState == .won)
    }
    
    @Test("Complete game flow works correctly")
    func completeGameFlow() async throws {
        let viewModel = ContentViewModel()
        
        #expect(viewModel.viewState.gameState == .initial)
        
        await viewModel.handle(.spin)
                        
        #expect(viewModel.viewState.gameState == .choosing)
        
        let selectedColor = viewModel.viewState.spinnableWheel.selectedColor
        let bestContrast = selectedColor.perceptualContrastingColor() == .black ? ContrastChoice.dark : ContrastChoice.light
        
        await viewModel.handle(.choose(contrast: bestContrast))
        
        #expect(viewModel.viewState.gameState == .correct)
        
        await viewModel.handle(.cashOut)
        
        #expect(viewModel.viewState.gameState == .won)
        
        await viewModel.handle(.startNewGame)
        
        #expect(viewModel.viewState.gameState == .initial)
    }
    
    @Test("Losing game flow works correctly")
    func losingGameFlow() async throws {
        let viewModel = ContentViewModel()
        await viewModel.handle(.spin)
        let selectedColor = viewModel.viewState.spinnableWheel.selectedColor
        let worstContrast = selectedColor.perceptualContrastingColor() == .black ? ContrastChoice.light : ContrastChoice.dark
        viewModel.viewState.status.points = 10
        
        await viewModel.handle(.choose(contrast: worstContrast))
        
        #expect(viewModel.viewState.gameState == .lost)
        #expect(viewModel.viewState.status.points == 0)
    }
    
    @Test("Wheel radius change updates ball offset", arguments: [1, CGFloat.greatestFiniteMagnitude])
    func wheelRadiusChangedTest(radius: CGFloat) async throws {
        let viewModel = ContentViewModel()
        let ballOffset = viewModel.viewState.spinnableWheel.ballOffset
        
        await viewModel.handle(.wheelRadiusChanged(radius: radius))
        
        #expect(viewModel.viewState.spinnableWheel.ballOffset != ballOffset)
    }
}

