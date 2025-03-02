//
//  OtherActionsView.swift
//  ColoRoulette
//
//  Created by Greg Turek on 3/2/25.
//

import SwiftUI

struct OtherActionsView: View {
    let viewModel: ContentViewModel
    private var gameState: GameState { viewModel.viewState.gameState }
    
    var body: some View {
        VStack {
            otherActionText
            otherActionButtons
        }
        .frame(maxWidth: .infinity)
    }
    
    private var otherActionText: some View {
        Text({
            switch gameState {
            case .initial:
                "Spin to play!"
            case .spinning:
                "Spinning..."
            case .choosing:
                "Best contrast with above?"
            case .correct:
                "Spin or cash out?"
            case .won:
                "You won!"
            case .lost:
                "You lost!"
            }
        }())
        .multilineTextAlignment(.center)
        .accessibilityIdentifier("GameStateText")
    }
    
    private var otherActionButtons: some View {
        HStack {
            if [.choosing, .correct, .won, .lost].contains(gameState) {
                HStack {
                    GlowingButton(
                        respondsToPress: gameState == .choosing,
                        action: { Task { @MainActor in await viewModel.handle(.choose(contrast: .light)) }}
                    ) {
                        Text(" ")
                            .accessibilityLabel(Text("White"))
                            .frame(maxWidth: .infinity)
                            .opacity(0)
                    }
                    .tint(.white)
                    .accessibilityIdentifier({
                        if ProcessInfo.processInfo.arguments.contains("--uitesting") && gameState == .choosing {
                            let selectedColor = viewModel.viewState.spinnableWheel.selectedColor
                            let isWhiteBetter = selectedColor.perceptualContrastingColor() != .black
                            return isWhiteBetter ? "CorrectChoiceButton" : "WhiteButton"
                        }
                        return "WhiteButton"
                    }())
                    
                    if gameState == .correct {
                        GlowingButton(action: { Task { @MainActor in await viewModel.handle(.cashOut) }}) {
                            Text("Cash Out")
                                .frame(maxWidth: .infinity)
                        }
                        .layoutPriority(1)
                        .tint(.green.adjustingPerceivedLightness(by: 15))
                        .foregroundStyle(.green.adjustingPerceivedLightness(by: 15).perceptualContrastingColor())
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityIdentifier("CashOutButton")
                    } else if [.won, .lost].contains(gameState) {
                        GlowingButton(action: { Task { @MainActor in await viewModel.handle(.startNewGame) }}) {
                            Text("New Game")
                                .frame(maxWidth: .infinity)
                        }
                        .layoutPriority(1)
                        .tint(
                            gameState == .won ? .green.adjustingPerceivedLightness(
                                by: 15
                            ) : .red.adjustingPerceivedLightness(
                                by: -10
                            )
                        )
                        .foregroundStyle(
                            gameState == .won ? .green.adjustingPerceivedLightness(
                                by: 15
                            ).perceptualContrastingColor() : .red.adjustingPerceivedLightness(
                                by: -10
                            ).perceptualContrastingColor()
                        )
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityIdentifier("NewGameButton")
                    }
                    
                    GlowingButton(
                        respondsToPress: gameState == .choosing,
                        action: { Task { @MainActor in await viewModel.handle(.choose(contrast: .dark)) }}
                    ) {
                        Text(" ")
                            .accessibilityLabel(Text("Black"))
                            .frame(maxWidth: .infinity)
                            .opacity(0)
                    }
                    .tint(.black)
                    .accessibilityIdentifier({
                        if ProcessInfo.processInfo.arguments.contains("--uitesting") && gameState == .choosing {
                            let selectedColor = viewModel.viewState.spinnableWheel.selectedColor
                            let isBlackBetter = selectedColor.perceptualContrastingColor() == .black
                            return isBlackBetter ? "CorrectChoiceButton" : "BlackButton"
                        }
                        return "BlackButton"
                    }())
                }
                .animation(.spring(duration: 0.25), value: gameState)
            } else {
                Button(" ") {}.hidden().accessibilityHidden(true)
            }
        }
        .buttonStyle(.borderedProminent)
        .padding(16)
        .background(.secondary.shadow(.inner(color: .black, radius: 4)))
        .background(in: .capsule)
        .opacity([.initial, .spinning].contains(gameState) ? 0 : 1)
    }
}
