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
                // Fixed: Timer Display + Control Buttons
                VStack(spacing: 0) {
                    Text(viewModel.formattedTime)
                        .font(.system(size: 60, weight: .light, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 20)
                        .padding(.bottom, 24)

                    HStack(spacing: 20) {
                        Button(action: { viewModel.reset() }) {
                            Image(systemName: "trash")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color(.systemGray4))
                                .clipShape(Circle())
                        }

                        Button(action: {
                            if viewModel.isRunning { viewModel.stop() } else { viewModel.start() }
                        }) {
                            Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundStyle(viewModel.isRunning ? .white : .black)
                                .frame(width: 64, height: 64)
                                .background(viewModel.isRunning ? Color(.systemGray4) : .orange)
                                .clipShape(Circle())
                        }

                        Button(action: { viewModel.addLap() }) {
                            Image(systemName: "flag")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 64, height: 64)
                                .background(Color(.systemGray4))
                                .clipShape(Circle())
                        }

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
                }
                .background(Color.black)

                // Scrollable: Laps only
                ScrollView {
                    VStack(spacing: 0) {
                        if !viewModel.laps.isEmpty {
                            ForEach(viewModel.laps.reversed()) { lap in
                                LapRowView(lap: lap, viewModel: viewModel)
                                Divider().background(Color(.systemGray5).opacity(0.3))
                            }
                        }
                        Spacer(minLength: 20)
                    }
                }
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

// MARK: - Lap Row

struct LapRowView: View {
    let lap: StopwatchViewModel.Lap
    @ObservedObject var viewModel: StopwatchViewModel

    private var isExpanded: Bool { viewModel.expandedLapId == lap.id }

    var body: some View {
        VStack(spacing: 0) {
            // Header row (tappable)
            Button(action: { viewModel.toggleLapCalculation(lap.id) }) {
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
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Calculation history for this lap
            if let history = viewModel.lapCalcHistory[lap.id], !history.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    ForEach(history, id: \.self) { item in
                        Text(item)
                            .font(.caption2)
                            .foregroundStyle(Color(.systemGray))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            // Expanded calculator
            if isExpanded {
                LapCalculatorView(lap: lap, viewModel: viewModel)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
        }
        .background(isExpanded ? Color(.systemGray6).opacity(0.15) : Color.clear)
    }
}

// MARK: - Lap Calculator

struct LapCalculatorView: View {
    let lap: StopwatchViewModel.Lap
    @ObservedObject var viewModel: StopwatchViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Expression display
            HStack {
                Text(viewModel.lapCalcDisplayText(for: lap.id))
                    .font(.system(size: 22, weight: .light, design: .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.systemGray6).opacity(0.3))
            .cornerRadius(8)

            // Undo button
            if viewModel.hasLapHistory(lap.id) {
                Button(action: { viewModel.undoLapChange(lap.id) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("元に戻す")
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .buttonStyle(.plain)
            }

            // Calculator button grid
            let btnH: CGFloat = 44
            VStack(spacing: 6) {
                // Row 1: AC, ⌫, ÷, ×
                HStack(spacing: 6) {
                    LapCalcButton(label: "AC", style: .gray) { viewModel.clearLapCalculation() }
                    LapCalcButton(label: "⌫", style: .gray) { viewModel.lapCalcBackspace() }
                    LapCalcButton(label: "÷", style: .orange) { viewModel.lapCalcOperationPress("/") }
                    LapCalcButton(label: "×", style: .orange) { viewModel.lapCalcOperationPress("*") }
                }
                // Row 2: 7, 8, 9, -
                HStack(spacing: 6) {
                    LapCalcButton(label: "7", style: .dark) { viewModel.lapCalcNumberPress(7) }
                    LapCalcButton(label: "8", style: .dark) { viewModel.lapCalcNumberPress(8) }
                    LapCalcButton(label: "9", style: .dark) { viewModel.lapCalcNumberPress(9) }
                    LapCalcButton(label: "-", style: .orange) { viewModel.lapCalcOperationPress("-") }
                }
                // Row 3: 4, 5, 6, +
                HStack(spacing: 6) {
                    LapCalcButton(label: "4", style: .dark) { viewModel.lapCalcNumberPress(4) }
                    LapCalcButton(label: "5", style: .dark) { viewModel.lapCalcNumberPress(5) }
                    LapCalcButton(label: "6", style: .dark) { viewModel.lapCalcNumberPress(6) }
                    LapCalcButton(label: "+", style: .orange) { viewModel.lapCalcOperationPress("+") }
                }
                // Row 4+5: 1,2,3 / 0,分 + = (tall, right column)
                HStack(spacing: 6) {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            LapCalcButton(label: "1", style: .dark) { viewModel.lapCalcNumberPress(1) }
                            LapCalcButton(label: "2", style: .dark) { viewModel.lapCalcNumberPress(2) }
                            LapCalcButton(label: "3", style: .dark) { viewModel.lapCalcNumberPress(3) }
                        }
                        HStack(spacing: 6) {
                            Button(action: { viewModel.lapCalcNumberPress(0) }) {
                                Text("0")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: btnH)
                                    .background(Color(.systemGray4).opacity(0.6))
                                    .cornerRadius(8)
                            }
                            LapCalcButton(label: "分", style: .gray) { viewModel.lapCalcMinutesPress() }
                        }
                    }
                    // Tall = button
                    Button(action: { viewModel.executeLapCalculation(lap.id) }) {
                        Text("=")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: btnH * 2 + 6)
                            .background(.orange)
                            .cornerRadius(8)
                    }
                    .frame(width: (UIScreen.main.bounds.width - 24 - 18) / 4)
                }
            }
        }
    }
}

// MARK: - Lap Calc Button

struct LapCalcButton: View {
    enum Style { case gray, dark, orange }
    let label: String
    let style: Style
    let action: () -> Void

    var bg: Color {
        switch style {
        case .gray: return Color(.systemGray4)
        case .dark: return Color(.systemGray4).opacity(0.6)
        case .orange: return .orange
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(bg)
                .cornerRadius(8)
        }
    }
}

#Preview {
    StopwatchView()
        .preferredColorScheme(.dark)
}
