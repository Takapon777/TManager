//
//  StopwatchView.swift
//  TManager
//
//  Created by Hanoi on 2026/04/02.
//

import SwiftUI

struct StopwatchView: View {
    @StateObject private var viewModel = StopwatchViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Timer Display
                Text(viewModel.formattedTime)
                    .font(.system(size: 60, weight: .light, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                // Control Buttons
                HStack(spacing: 20) {
                    // Reset
                    Button(action: { viewModel.reset() }) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color(.systemGray4))
                            .clipShape(Circle())
                    }

                    // Start/Pause
                    Button(action: {
                        if viewModel.isRunning {
                            viewModel.stop()
                        } else {
                            viewModel.start()
                        }
                    }) {
                        Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundStyle(viewModel.isRunning ? .white : .black)
                            .frame(width: 64, height: 64)
                            .background(viewModel.isRunning ? Color(.systemGray4) : .orange)
                            .clipShape(Circle())
                    }

                    // Lap
                    Button(action: { viewModel.addLap() }) {
                        Image(systemName: "flag")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Color(.systemGray4))
                            .clipShape(Circle())
                    }

                    // Final Stop
                    Button(action: { viewModel.finalStop() }) {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(.orange)
                            .clipShape(Circle())
                    }
                    .disabled(!viewModel.isRunning)
                    .opacity(viewModel.isRunning ? 1.0 : 0.5)
                }
                .padding(.bottom, 20)

                // Lap List
                if !viewModel.laps.isEmpty {
                    List {
                        ForEach(viewModel.laps.reversed()) { lap in
                            HStack {
                                Text("ラップ \(lap.id)")
                                    .foregroundStyle(.gray)
                                    .font(.subheadline)

                                Spacer()

                                HStack(spacing: 16) {
                                    Text(viewModel.formatTime(lap.lapTime))
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundStyle(.white)

                                    Text(viewModel.formatTime(lap.totalTime))
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.gray)
                                }
                            }
                            .listRowBackground(Color(.systemGray6).opacity(0.3))
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    StopwatchView()
        .preferredColorScheme(.dark)
}
