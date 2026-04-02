//
//  ContentView.swift
//  TManager
//
//  Created by Hanoi on 2026/04/02.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                StopwatchView()
                    .tabItem {
                        Label("ストップウォッチ", systemImage: "stopwatch")
                    }
                    .tag(0)

                TimeCalculatorView()
                    .tabItem {
                        Label("時間電卓", systemImage: "plus.forwardslash.minus")
                    }
                    .tag(1)

                AgeCalculatorView()
                    .tabItem {
                        Label("年齢", systemImage: "person.badge.clock")
                    }
                    .tag(2)
            }
            .tint(.orange)
        }
    }
}

#Preview {
    ContentView()
}
