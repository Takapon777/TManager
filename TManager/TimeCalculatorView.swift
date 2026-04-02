//
//  TimeCalculatorView.swift
//  TManager
//
//  Created by Hanoi on 2026/04/02.
//

import SwiftUI

struct TimeCalculatorView: View {
    @StateObject private var viewModel = TimeCalculatorViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // History Area
                VStack(alignment: .trailing) {
                    if !viewModel.historyText.isEmpty {
                        Text(viewModel.historyText)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        Text("履歴なし")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .frame(height: 60)
                .background(Color(.systemGray6).opacity(0.3))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 10)

                Spacer()

                // Expression
                if !viewModel.expressionText.isEmpty {
                    Text(viewModel.expressionText)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal)
                }

                // Main Display
                HStack {
                    Spacer()
                    Text(viewModel.displayString)
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.5)
                }
                .padding()
                .frame(height: 80)
                .background(Color(.systemGray6).opacity(0.3))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 16)

                // Calculator Buttons
                VStack(spacing: 10) {
                    // Row 1: AC, ÷, ÷, ×
                    HStack(spacing: 10) {
                        CalcButton(label: "AC", style: .gray) {
                            viewModel.allClear()
                        }
                        CalcButton(label: "⌫", style: .gray) {
                            viewModel.backspace()
                        }
                        CalcButton(label: "÷", style: .orange) {
                            viewModel.inputOperation("÷")
                        }
                        CalcButton(label: "×", style: .orange) {
                            viewModel.inputOperation("×")
                        }
                    }

                    // Row 2: 7, 8, 9, -
                    HStack(spacing: 10) {
                        CalcButton(label: "7", style: .dark) { viewModel.inputDigit(7) }
                        CalcButton(label: "8", style: .dark) { viewModel.inputDigit(8) }
                        CalcButton(label: "9", style: .dark) { viewModel.inputDigit(9) }
                        CalcButton(label: "-", style: .orange) {
                            viewModel.inputOperation("-")
                        }
                    }

                    // Row 3: 4, 5, 6, +
                    HStack(spacing: 10) {
                        CalcButton(label: "4", style: .dark) { viewModel.inputDigit(4) }
                        CalcButton(label: "5", style: .dark) { viewModel.inputDigit(5) }
                        CalcButton(label: "6", style: .dark) { viewModel.inputDigit(6) }
                        CalcButton(label: "+", style: .orange) {
                            viewModel.inputOperation("+")
                        }
                    }

                    // Row 4: 1, 2, 3, =
                    HStack(spacing: 10) {
                        CalcButton(label: "1", style: .dark) { viewModel.inputDigit(1) }
                        CalcButton(label: "2", style: .dark) { viewModel.inputDigit(2) }
                        CalcButton(label: "3", style: .dark) { viewModel.inputDigit(3) }

                        // = button (spans 2 rows)
                        Button(action: { viewModel.calculate() }) {
                            Text("=")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 130)
                                .background(.orange)
                                .cornerRadius(10)
                        }
                    }

                    // Row 5: 0 (wide), 分
                    HStack(spacing: 10) {
                        // 0 spans 2 columns
                        Button(action: { viewModel.inputDigit(0) }) {
                            Text("0")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(.systemGray4))
                                .cornerRadius(10)
                        }

                        CalcButton(label: "分", style: .gray) {
                            viewModel.inputMinutesMode()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
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

// MARK: - Calculator Button
struct CalcButton: View {
    enum Style {
        case gray, dark, orange
    }

    let label: String
    let style: Style
    let action: () -> Void

    var backgroundColor: Color {
        switch style {
        case .gray: return Color(.systemGray4)
        case .dark: return Color(.systemGray4).opacity(0.6)
        case .orange: return .orange
        }
    }

    var foregroundColor: Color {
        switch style {
        case .gray: return .black
        case .dark: return .white
        case .orange: return .white
        }
    }

    var fontWeight: Font.Weight {
        switch style {
        case .gray: return .semibold
        case .dark: return .semibold
        case .orange: return .bold
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: label == "÷" || label == "×" || label == "-" || label == "+" ? 24 : 20, weight: fontWeight))
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(backgroundColor)
                .cornerRadius(10)
        }
    }
}

#Preview {
    TimeCalculatorView()
}
