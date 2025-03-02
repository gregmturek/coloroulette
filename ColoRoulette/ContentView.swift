//
//  ContentView.swift
//  ColoRoulette
//
//  Created by Greg Turek on 3/2/25.
//

import SwiftUI
import ColorPerception

struct ContentView: View {
    @State private var viewModel = ContentViewModel()
    
    var body: some View {
        VStack {
            StatusView(statusState: viewModel.viewState.status)
            Spacer()
            SpinnableWheelView(viewModel: viewModel)
            Spacer()
            OtherActionsView(viewModel: viewModel)
        }
        .scenePadding()
    }
}

#Preview {
    ContentView()
}
