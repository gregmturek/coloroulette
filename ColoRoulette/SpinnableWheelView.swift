//
//  SpinnableWheelView.swift
//  ColoRoulette
//
//  Created by Greg Turek on 3/2/25.
//

import SwiftUI
import CoreGraphics
import ColorPerception

struct SpinnableWheelView: View {
    let viewModel: ContentViewModel
    
    private var gameState: GameState { viewModel.viewState.gameState }
    private var wheelState: ViewState.SpinnableWheelState { viewModel.viewState.spinnableWheel }
    
    var body: some View {
        ZStack {
            WheelView(
                wedgeColors: wheelState.wedgeColors,
                wheelDegrees: wheelState.wheelDegrees,
                onWheelRadiusChange: { radius in
                    Task { @MainActor in
                        await viewModel.handle(.wheelRadiusChanged(radius: radius))
                    }
                }
            )
            
            SpinOrTimerView(
                gameState: gameState,
                choiceTimeLeft: wheelState.choiceTimeLeft,
                onSpin: {
                    Task { @MainActor in
                        await viewModel.handle(.spin)
                    }
                }
            )
            
            BallView(
                ballOffset: wheelState.ballOffset,
                ballDegrees: wheelState.ballDegrees
            )
            
            if [.correct, .won, .lost].contains(gameState) {
                InfoView(
                    selectedColor: wheelState.selectedColor,
                    whiteContrast: Color.white.perceivedContrast(against: wheelState.selectedColor),
                    blackContrast: Color.black.perceivedContrast(against: wheelState.selectedColor)
                )
            }
            
            ZStack {
                if [.won, .lost].contains(gameState) {
                    GameOverView(gameState: gameState)
                        .transition(.scale(scale: 0.95))
                }
            }
            .id(gameState == .initial)
            .animation(.easeInOut(duration: 1).repeatForever(), value: gameState)
        }
        .padding(.top, 32)
    }
}

private struct WheelView: View {
    let wedgeColors: [Color]
    let wheelDegrees: Double
    let onWheelRadiusChange: (CGFloat) async -> Void
    
    var body: some View {
        WedgeCircle(
            wedgeColors: wedgeColors,
            onRadiusChange: { radius in
                Task { @MainActor in
                    await onWheelRadiusChange(radius)
                }
            }
        )
        .rotationEffect(.degrees(wheelDegrees))
    }
}

private struct WedgeCircle: View {
    let wedgeColors: [Color]
    @State private var radius: CGFloat = .zero
    let onRadiusChange: ((CGFloat) -> Void)?
    
    var body: some View {
        let wedgeCount = wedgeColors.count
        let startAngleAdjustment = 90 + (360 / Double(wedgeCount) / 2)
        
        return ZStack {
            ForEach(0..<wedgeCount, id: \.self) { index in
                Wedge(
                    startAngle: .degrees(360 * Double(index) / Double(wedgeCount) - startAngleAdjustment),
                    endAngle: .degrees(360 * Double((index + 1)) / Double(wedgeCount) - startAngleAdjustment),
                    radius: radius
                )
                .fill(wedgeColors[index].shadow(.inner(color: .white, radius: 4)))
            }
        }
        .compositingGroup()
        .shadow(color: .primary, radius: 8)
        .aspectRatio(1, contentMode: .fit)
        .overlay(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        updateRadius(to: geometry.size.width / 2)
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        updateRadius(to: newSize.width / 2)
                    }
            }
        )
    }
    
    private func updateRadius(to radius: CGFloat) {
        if self.radius != radius {
            self.radius = radius
            onRadiusChange?(radius)
        }
    }
}

private struct Wedge: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let start = CGPoint(
            x: center.x + radius * cos(startAngle.radians),
            y: center.y + radius * sin(startAngle.radians)
        )
        
        path.move(to: center)
        path.addLine(to: start)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addLine(to: center)
        
        return path
    }
}

private struct SpinOrTimerView: View {
    let gameState: GameState
    let choiceTimeLeft: Int
    let onSpin: () async -> Void
    
    var body: some View {
        ZStack {
            Text("$\(choiceTimeLeft)")
                .padding(16)
                .opacity(gameState == .choosing ? 1 : 0)
                .accessibilityIdentifier("ChoiceTimer")
            
            GlowingButton(
                shape: .circle,
                glowColor: Color(UIColor.systemBackground),
                action: { Task { @MainActor in await onSpin() }}
            ) {
                Text("Spin")
                    .padding(16)
                    .opacity([.initial, .correct].contains(gameState) ? 1 : 0)
                    .animation(.easeOut(duration: 0.25), value: gameState)
            }
            .id(gameState == .choosing)
            .buttonStyle(.bordered)
            .opacity([.initial, .correct, .spinning].contains(gameState) ? 1 : 0)
            .disabled(gameState == .spinning)
            .accessibilityIdentifier("SpinButton")
        }
        .background(.tertiary.shadow(.inner(color: .black, radius: 4)))
        .background(in: .circle)
        .foregroundStyle(.primary)
    }
}

private struct BallView: View {
    let ballOffset: CGFloat
    let ballDegrees: Double
    
    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: 24, height: 24)
            .overlay(Circle().stroke(Color.black.opacity(0.67), style: StrokeStyle(lineWidth: 1)))
            .shadow(color: .gray, radius: 1)
            .blur(radius: 0.25)
            .offset(y: ballOffset)
            .rotationEffect(.degrees(ballDegrees))
    }
}

private struct InfoView: View {
    let selectedColor: Color
    let whiteContrast: Double
    let blackContrast: Double
    
    var body: some View {
        HStack {
            VStack {
                Text("White")
                    .foregroundColor(selectedColor)
                    .shadow(color: .black, radius: 0.25)
                Text("Contrast:\n\(whiteContrast.formatted(.number.precision(.fractionLength(0))))")
                    .foregroundColor(.black)
            }
            .font(.callout.weight(.heavy))
            .multilineTextAlignment(.center)
            .padding(8)
            .background(.white.shadow(.drop(color: .gray, radius: 4)), in: .rect(cornerRadius: 16))
            
            Spacer()
            
            VStack {
                Text("Black")
                    .foregroundColor(selectedColor)
                    .shadow(color: .white, radius: 0.25)
                Text("Contrast:\n\(blackContrast.formatted(.number.precision(.fractionLength(0))))")
                    .foregroundColor(.white)
            }
            .font(.callout.weight(.heavy))
            .multilineTextAlignment(.center)
            .padding(8)
            .background(.black.shadow(.drop(color: .gray, radius: 4)), in: .rect(cornerRadius: 16))
        }
        .padding()
        .background(.clear)
    }
}

private struct GameOverView: View {
    let gameState: GameState
    
    var body: some View {
        VStack {
            Text("Game Over!")
                .font(.title)
        }
        .padding(8)
        .foregroundColor(gameState == .won ? .green.adjustingPerceivedLightness(
            by: 15
        ).perceptualContrastingColor() : .red.adjustingPerceivedLightness(
            by: -10
        ).perceptualContrastingColor())
        .background(
            (gameState == .won ? Color.green.adjustingPerceivedLightness(
                by: 15
            ) : Color.red.adjustingPerceivedLightness(
                by: -10
            ))
            .shadow(.drop(color: .gray, radius: 4)), in: .rect(cornerRadius: 16)
        )
    }
}
