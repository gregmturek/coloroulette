//
//  GlowingButton.swift
//  ColoRoulette
//
//  Created by Greg Turek on 3/2/25.
//

import SwiftUI

struct GlowingButton<Label: View>: View {
    var shape: ButtonBorderShape = .capsule
    var glowColor: Color = .white
    var respondsToPress = true
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            guard respondsToPress else { return }
            isPressed = true
            action()
        }) {
            label()
        }
        .background(
            glowColor
                .clipShape(shape)
                .opacity(isPressed ? 1 : 0)
                .blur(radius: 3)
                .animation(.easeOut(duration: 0.25), value: isPressed)
        )
        .buttonBorderShape(shape)
    }
}
