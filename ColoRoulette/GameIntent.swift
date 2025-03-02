//
//  GameIntent.swift
//  ColoRoulette
//
//  Created by Greg Turek on 3/2/25.
//

import ColorPerception
import Foundation

enum GameIntent {
    case spin
    case choose(contrast: ContrastChoice)
    case cashOut
    case startNewGame
    case wheelRadiusChanged(radius: CGFloat)
}
