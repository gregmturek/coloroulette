//
//  ContentViewModel.swift
//  ColoRoulette
//
//  Created by Greg Turek on 3/2/25.
//

import ColorPerception
import SwiftUI

@MainActor
@Observable
final class ContentViewModel {
    let viewState = ViewState()
    let spinDuration: TimeInterval = 3
    
    private let defaultSpinRevolutions = 3.0
    private var spinRevolutions = 0.0
    private var selectedIndex = 0
    private var wheelRadius: CGFloat = 0
    private var ballOffset: CGFloat { -(wheelRadius) }
    private let inactiveBallOffsetAdjustment: CGFloat = -20
    private let activeBallOffsetAdjustment: CGFloat = 10
    private var gameStateRelativeBallOffset: CGFloat {
        let wheelEdgeOffset: CGFloat = [
            .spinning,
            .choosing
        ].contains(
            viewState.gameState
        ) ? activeBallOffsetAdjustment : inactiveBallOffsetAdjustment
        return ballOffset + wheelEdgeOffset
    }
    
    private let levelBaseColorAndLightnesses: [(baseColor: Color, lightnesses: [Double])] = [
        (.blue , [25, 75, 100]),
        (.green ,[0, 25, 75]),
        (.red , [25, 75, 100]),
        (.cyan , [0, 25, 75]),
        (.pink , [25, 75, 100]),
        (.yellow, [0, 25, 75]),
        (.blue, [20, 60, 40, 80]),
        (.green, [20, 60, 40, 80]),
        (.red, [20, 60, 40, 80]),
        (.cyan, [20, 60, 40, 80]),
        (.pink, [20, 60, 40, 80]),
        (.yellow, [20, 60, 40, 80]),
        (.blue, [25, 65, 45, 55, 35, 75]),
        (.green, [25, 65, 45, 55, 35, 75]),
        (.red, [25, 65, 45, 55, 35, 75]),
        (.cyan, [25, 65, 45, 55, 35, 75]),
        (.pink, [25, 65, 45, 55, 35, 75]),
        (.yellow, [25, 65, 45, 55, 35, 75])
    ]

    private var choiceTimerTask: Task<Void, Never>?
    
    init() {
        viewState.status.levels = levelBaseColorAndLightnesses.count
        
        if ProcessInfo.processInfo.arguments.contains("--uitesting-last-level") {
            viewState.status.level = viewState.status.levels
            viewState.status.points = 100
        }
        
        configureSpinnableWheel()
    }
    
    private func configureSpinnableWheel(with animation: Animation? = .none) {
        withAnimation(animation) {
            viewState.spinnableWheel.wheelDegrees = 0
            
            guard !levelBaseColorAndLightnesses.isEmpty else {
                handleMissingData()
                return
            }
            
            let levelIndex = max(0, min(viewState.status.level - 1, levelBaseColorAndLightnesses.count - 1))
            let (baseColor, lightnesses) = levelBaseColorAndLightnesses[levelIndex]
            
            guard !lightnesses.isEmpty else {
                handleMissingData(using: baseColor)
                return
            }

            viewState.spinnableWheel.wedgeColors = lightnesses.map { lightness in
                baseColor.withPerceivedLightness(lightness)
            }

            let randomLightness = lightnesses.randomElement()!  // Safe due to guard

            viewState.spinnableWheel.selectedColor = baseColor.withPerceivedLightness(randomLightness)

            selectedIndex = lightnesses.firstIndex(of: randomLightness)!  // Safe due to guard

            let wedgeCount = Double(lightnesses.count)
            
            spinRevolutions = defaultSpinRevolutions + ((wedgeCount - Double(selectedIndex)) / wedgeCount)
            
            @MainActor func handleMissingData(using color: Color = .gray) {
                viewState.spinnableWheel.wedgeColors = [color]
                viewState.spinnableWheel.selectedColor = color
                selectedIndex = 0
                spinRevolutions = defaultSpinRevolutions
            }
        }
    }

    func handle(_ intent: GameIntent) async {
        switch intent {
        case .spin:
            if viewState.gameState != .initial {
                withAnimation(.easeOut(duration: 0.5)) {
                    viewState.status.level += 1
                }
                configureSpinnableWheel()
            }
            updateGameState(to: .spinning)
        case .choose(let contrast):
            let isBlackBestContrast = viewState.spinnableWheel.selectedColor.perceptualContrastingColor() == .black
            if (isBlackBestContrast && contrast == .dark) || (!isBlackBestContrast && contrast == .light) {
                withAnimation(.easeOut(duration: 0.5)) {
                    viewState.status.points += viewState.spinnableWheel.choiceTimeLeft
                }
                if viewState.status.level == viewState.status.levels {
                    updateGameState(to: .won)
                } else {
                    updateGameState(to: .correct)
                }
            } else {
                viewState.status.points = 0
                updateGameState(to: .lost)
            }
        case .cashOut:
            updateGameState(to: .won)
        case .startNewGame:
            viewState.status.level = 1
            viewState.status.points = 0
            selectedIndex = 0
            updateGameState(to: .initial)
        case .wheelRadiusChanged(let radius):
            wheelRadius = radius
            resetBall()
        }
    }
    
    private func updateGameState(to state: GameState) {
        viewState.updateGameState(to: state) {
            doAfterGameStateUpdate()
        }
    }
    
    private func doAfterGameStateUpdate() {
        switch viewState.gameState {
        case .spinning:
            spin()
        case .choosing:
            startChoiceTimer()
        case .initial:
            configureSpinnableWheel(with: .easeOut)
            fallthrough
        case .correct, .won, .lost:
            resetBall(with: .easeOut)
            choiceTimerTask?.cancel()
        }
    }

    private func spin() {
        withAnimation(.easeOut(duration: spinDuration / 9)) {
            viewState.spinnableWheel.ballOffset = ballOffset / 2
        }

        withAnimation(.easeIn(duration: spinDuration / 9)) {
            viewState.spinnableWheel.ballOffset = gameStateRelativeBallOffset
        }

        withAnimation(
            .easeInOut(duration: spinDuration)
                .repeatCount(1, autoreverses: false)
        ) {
            viewState.spinnableWheel.wheelDegrees += 360 * spinRevolutions
        } completion: {
            self.updateGameState(to: .choosing)
        }

        withAnimation(
            .snappy(duration: spinDuration)
                .repeatCount(1, autoreverses: false)
        ) {
            viewState.spinnableWheel.ballDegrees -= 360 * defaultSpinRevolutions
        }
    }
    
    private func startChoiceTimer() {
        viewState.spinnableWheel.choiceTimeLeft = 10
        choiceTimerTask?.cancel()
        choiceTimerTask = Task { @MainActor in
            while viewState.gameState == .choosing && viewState.spinnableWheel.choiceTimeLeft > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                if viewState.gameState != .choosing { return }
                viewState.spinnableWheel.choiceTimeLeft -= 1
                if viewState.spinnableWheel.choiceTimeLeft <= 0 {
                    updateGameState(to: .lost)
                    return
                }
            }
        }
    }
    
    private func resetBall(with animation: Animation? = .none) {
        withAnimation(animation) {
            viewState.spinnableWheel.ballOffset = gameStateRelativeBallOffset
        }
        viewState.spinnableWheel.ballDegrees = 0
    }
}
