//
//  StatusView.swift
//  ColoRoulette
//
//  Created by Greg Turek on 3/2/25.
//

import SwiftUI

struct StatusView: View {
    let statusState: ViewState.StatusState
    
    var body: some View {
        HStack {
            HStack(spacing: 0) {
                Text("Level ")
                Text("\(statusState.level)")
                    .id("Level_\(statusState.level)")
                    .transition(.push(from: .top))
                Text("/\(statusState.levels)")
            }
            Spacer()
            HStack(spacing: 0) {
                Text("$")
                Text("\(statusState.points)")
                    .id("$\(statusState.points)")
                    .transition(.push(from: .bottom))
                
            }
        }
        .padding(8)
        .background(.quaternary.shadow(.inner(color: .black, radius: 4)), in: .rect(cornerRadius: 16))
        .font(.headline)
    }
}
