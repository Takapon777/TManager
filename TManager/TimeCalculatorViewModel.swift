//
//  TimeCalculatorViewModel.swift
//  TManager
//
//  Created by Hanoi on 2026/04/02.
//

import Foundation
import Combine

@MainActor
class TimeCalculatorViewModel: ObservableObject {
    @Published var displayMinutes: Int = 0
    @Published var displaySeconds: Int = 0
    @Published var history: [String] = []
    @Published var expressionText: String = ""

    private var currentValue: Int = 0  // stored in total seconds
    private var pendingValue: Int = 0
    private var pendingOp: String = ""
    private var waitingForOperand: Bool = false
    private var inputMinutes: Int = 0
    private var inputSeconds: Int = 0
    private var isEnteringSeconds: Bool = false
    private var hasDecimal: Bool = false  // tracks if "分" was pressed

    var displayString: String {
        String(format: "%02d:%02d", displayMinutes, displaySeconds)
    }

    func inputDigit(_ digit: Int) {
        if waitingForOperand {
            displayMinutes = 0
            displaySeconds = 0
            inputMinutes = 0
            inputSeconds = 0
            isEnteringSeconds = false
            hasDecimal = false
            waitingForOperand = false
        }

        if !isEnteringSeconds {
            // Entering minutes
            inputMinutes = inputMinutes * 10 + digit
            if inputMinutes > 999 { inputMinutes = 999 }
            displayMinutes = inputMinutes
        } else {
            // Entering seconds
            inputSeconds = inputSeconds * 10 + digit
            if inputSeconds >= 60 {
                // Overflow seconds to minutes
                inputMinutes += inputSeconds / 60
                inputSeconds = inputSeconds % 60
            }
            displayMinutes = inputMinutes
            displaySeconds = inputSeconds
        }
    }

    func inputMinutesMode() {
        isEnteringSeconds = true
        hasDecimal = true
    }

    func inputOperation(_ op: String) {
        let enteredValue = displayMinutes * 60 + displaySeconds

        if waitingForOperand {
            // Just change the operation
            pendingOp = op
            updateExpression(op)
            return
        }

        if !pendingOp.isEmpty {
            // Chain calculation
            let result = calculate(currentValue, pendingValue: enteredValue, op: pendingOp)
            currentValue = result
            setDisplayFromSeconds(result)
        } else {
            currentValue = enteredValue
        }

        pendingValue = enteredValue
        pendingOp = op
        waitingForOperand = true
        isEnteringSeconds = false
        hasDecimal = false

        updateExpression(formatSeconds(enteredValue) + " " + op + " ")
    }

    func calculate() {
        let enteredValue = displayMinutes * 60 + displaySeconds

        if pendingOp.isEmpty {
            return
        }

        let result = calculate(currentValue, pendingValue: enteredValue, op: pendingOp)
        let expression = "\(formatSeconds(currentValue)) \(pendingOp) \(formatSeconds(enteredValue)) = \(formatSeconds(result))"
        history.insert(expression, at: 0)

        currentValue = result
        setDisplayFromSeconds(result)
        pendingOp = ""
        waitingForOperand = true
        isEnteringSeconds = false
        hasDecimal = false
        expressionText = ""
    }

    func allClear() {
        displayMinutes = 0
        displaySeconds = 0
        inputMinutes = 0
        inputSeconds = 0
        currentValue = 0
        pendingValue = 0
        pendingOp = ""
        waitingForOperand = false
        isEnteringSeconds = false
        hasDecimal = false
        history = []
        expressionText = ""
    }

    func backspace() {
        if waitingForOperand { return }

        if isEnteringSeconds && inputSeconds > 0 {
            inputSeconds = inputSeconds / 10
            displaySeconds = inputSeconds
        } else if !isEnteringSeconds && inputMinutes > 0 {
            inputMinutes = inputMinutes / 10
            displayMinutes = inputMinutes
        } else if isEnteringSeconds {
            isEnteringSeconds = false
            hasDecimal = false
        }
    }

    private func calculate(_ a: Int, pendingValue b: Int, op: String) -> Int {
        switch op {
        case "+":
            return a + b
        case "-":
            return max(0, a - b)
        case "×":
            return a * b
        case "÷":
            return b != 0 ? a / b : 0
        default:
            return b
        }
    }

    private func setDisplayFromSeconds(_ totalSeconds: Int) {
        let seconds = max(0, totalSeconds)
        displayMinutes = seconds / 60
        displaySeconds = seconds % 60
        inputMinutes = displayMinutes
        inputSeconds = displaySeconds
    }

    private func formatSeconds(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func updateExpression(_ text: String) {
        expressionText += text
    }
}
