//
//  ViewState.swift
//  ColoRoulette
//
//  Created by Greg Turek on 3/2/25.
//

import SwiftUI

@Observable
final class ViewState {    
    struct StatusState {
        var level = 1
        var levels = 1
        var points = 0
    }
    
    @Observable
    final class SpinnableWheelState {
        var ballOffset: CGFloat = 0
        var ballDegrees = 0.0
        var wheelDegrees = 0.0
        var wedgeColors: [Color] = []
        var selectedColor: Color = .black
        var choiceTimeLeft = 10
    }
    
    var gameState: GameState = .initial
    var status = StatusState()
    let spinnableWheel = SpinnableWheelState()

    func updateGameState(to newState: GameState, then do: () -> Void) {
        gameState = newState
        `do`()
    }
}
