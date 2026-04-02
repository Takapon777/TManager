//
//  StopwatchViewModel.swift
//  TManager
//
//  Created by Hanoi on 2026/04/02.
//

import Foundation
import Combine

@MainActor
class StopwatchViewModel: ObservableObject {
    @Published var elapsedSeconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var laps: [Lap] = []

    // Per-lap calculator
    @Published var expandedLapId: Int? = nil
    @Published var lapCalcHistory: [Int: [String]] = [:]

    // Calculator input state (for the currently expanded lap)
    @Published var lapCalcOp: String = ""
    @Published var lapCalcMinutes: Int = 0
    @Published var lapCalcSeconds: Int = 0
    @Published var lapCalcPrevious: Int = 0
    @Published var lapCalcCurrent: Int = 0
    @Published var lapCalcExpression: String = ""
    @Published var lapCalcStartedWithNumber: Bool = false

    private var lapTimeHistory: [Int: [Int]] = [:]
    private var timer: Timer?

    struct Lap: Identifiable {
        let id: Int
        var lapTime: Int
        var totalTime: Int
        let originalLapTime: Int
    }

    var formattedTime: String {
        formatTime(elapsedSeconds)
    }

    func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedSeconds += 1
            }
        }
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func finalStop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        if elapsedSeconds > 0 {
            addLap()
        }
    }

    func reset() {
        stop()
        elapsedSeconds = 0
        laps = []
        expandedLapId = nil
        lapCalcHistory = [:]
        lapTimeHistory = [:]
        resetLapCalcState()
    }

    func addLap() {
        let lapTime = laps.isEmpty ? elapsedSeconds : elapsedSeconds - (laps.last?.totalTime ?? 0)
        laps.append(Lap(id: laps.count + 1, lapTime: lapTime, totalTime: elapsedSeconds, originalLapTime: lapTime))
    }

    // MARK: - Per-Lap Calculator

    func toggleLapCalculation(_ lapId: Int) {
        if expandedLapId == lapId {
            expandedLapId = nil
        } else {
            expandedLapId = lapId
            resetLapCalcState()
        }
    }

    func clearLapCalculation() {
        resetLapCalcState()
        expandedLapId = nil
    }

    func lapCalcDisplayText(for lapId: Int) -> String {
        guard let lap = laps.first(where: { $0.id == lapId }) else { return "" }

        if lapCalcOp.isEmpty {
            if lapCalcMinutes > 0 || lapCalcSeconds > 0 {
                let n = normalizeTime(lapCalcMinutes, lapCalcSeconds)
                return formatTime(n.m * 60 + n.s)
            }
            if lapCalcCurrent > 0 { return formatTime(lapCalcCurrent) }
            return formatTime(lap.lapTime)
        }

        var display: String
        if lapCalcStartedWithNumber {
            display = lapCalcExpression.isEmpty ? (lapCalcPrevious > 0 ? formatTime(lapCalcPrevious) : "") : lapCalcExpression
        } else {
            display = lapCalcExpression.isEmpty
                ? (lapCalcPrevious > 0 ? formatTime(lapCalcPrevious) : formatTime(lap.lapTime))
                : lapCalcExpression
        }

        display += " \(displayOp(lapCalcOp)) "

        if lapCalcMinutes > 0 || lapCalcSeconds > 0 {
            if lapCalcOp == "*" || lapCalcOp == "/" {
                display += "\(lapCalcMinutes * 60 + lapCalcSeconds)"
            } else {
                let n = normalizeTime(lapCalcMinutes, lapCalcSeconds)
                display += formatTime(n.m * 60 + n.s)
            }
        }

        return display
    }

    func hasLapHistory(_ lapId: Int) -> Bool {
        guard let h = lapTimeHistory[lapId] else { return false }
        return !h.isEmpty
    }

    func lapCalcNumberPress(_ number: Int) {
        lapCalcSeconds = lapCalcSeconds * 10 + number
        if lapCalcMinutes == 0 && lapCalcSeconds == 0 && lapCalcOp.isEmpty {
            lapCalcStartedWithNumber = true
        }
    }

    func lapCalcMinutesPress() {
        guard lapCalcSeconds > 0 else { return }
        lapCalcMinutes = lapCalcSeconds
        lapCalcSeconds = 0
    }

    func lapCalcBackspace() {
        if lapCalcSeconds > 0 {
            lapCalcSeconds /= 10
        } else if lapCalcMinutes > 0 {
            lapCalcSeconds = lapCalcMinutes
            lapCalcMinutes = 0
        }
    }

    func lapCalcOperationPress(_ op: String) {
        guard let lapId = expandedLapId,
              let lap = laps.first(where: { $0.id == lapId }) else { return }

        let n = normalizeTime(lapCalcMinutes, lapCalcSeconds)
        let currentInSec = n.m * 60 + n.s

        if lapCalcStartedWithNumber {
            let val = (lapCalcMinutes == 0 && lapCalcSeconds == 0) ? (lapCalcCurrent > 0 ? lapCalcCurrent : 0) : currentInSec
            if lapCalcPrevious == 0 {
                lapCalcPrevious = val
                lapCalcExpression = formatTime(val)
            } else if !lapCalcOp.isEmpty && val > 0 {
                let result = applyOp(lapCalcPrevious, op: lapCalcOp, rhs: val)
                lapCalcExpression += " \(displayOp(lapCalcOp)) " + (isTimeOp(lapCalcOp) ? formatTime(val) : "\(val)")
                lapCalcPrevious = result
                lapCalcCurrent = result
            }
        } else {
            if lapCalcPrevious == 0 {
                lapCalcPrevious = lap.lapTime
                lapCalcExpression = formatTime(lap.lapTime)
            } else if !lapCalcOp.isEmpty && currentInSec > 0 {
                let result = applyOp(lapCalcPrevious, op: lapCalcOp, rhs: currentInSec)
                lapCalcExpression += " \(displayOp(lapCalcOp)) " + (isTimeOp(lapCalcOp) ? formatTime(currentInSec) : "\(currentInSec)")
                lapCalcPrevious = result
                lapCalcCurrent = result
                lapCalcMinutes = 0
                lapCalcSeconds = 0
            }
        }

        lapCalcOp = op
    }

    func executeLapCalculation(_ lapId: Int) {
        guard let lapIndex = laps.firstIndex(where: { $0.id == lapId }) else { return }
        let lap = laps[lapIndex]
        let currentTime = lap.lapTime
        let n = normalizeTime(lapCalcMinutes, lapCalcSeconds)
        let calcTimeSec = n.m * 60 + n.s

        // Save undo history
        var th = lapTimeHistory[lapId] ?? [lap.originalLapTime]
        th.append(currentTime)
        lapTimeHistory[lapId] = th

        var newTime: Int
        var calcText: String

        if lapCalcOp.isEmpty {
            newTime = lapCalcCurrent > 0 ? lapCalcCurrent : calcTimeSec
            calcText = "\(formatTime(currentTime)) → \(formatTime(newTime))"
        } else {
            let val = (lapCalcMinutes == 0 && lapCalcSeconds == 0) ? (lapCalcCurrent > 0 ? lapCalcCurrent : 0) : calcTimeSec
            var result = lapCalcPrevious
            var expr = lapCalcExpression
            if val > 0 {
                result = applyOp(lapCalcPrevious, op: lapCalcOp, rhs: val)
                expr += " \(displayOp(lapCalcOp)) " + (isTimeOp(lapCalcOp) ? formatTime(val) : "\(val)")
            }
            newTime = result
            calcText = "\(expr) = \(formatTime(result))"
        }

        laps[lapIndex].lapTime = newTime
        recalcTotals()

        var hist = lapCalcHistory[lapId] ?? []
        hist.append(calcText)
        lapCalcHistory[lapId] = hist

        expandedLapId = nil
        resetLapCalcState()
    }

    func undoLapChange(_ lapId: Int) {
        guard let lapIndex = laps.firstIndex(where: { $0.id == lapId }),
              let th = lapTimeHistory[lapId], !th.isEmpty else { return }

        laps[lapIndex].lapTime = th.last!
        lapTimeHistory[lapId] = Array(th.dropLast())
        recalcTotals()

        var hist = lapCalcHistory[lapId] ?? []
        if !hist.isEmpty { hist.removeLast() }
        lapCalcHistory[lapId] = hist
    }

    // MARK: - Helpers

    private func resetLapCalcState() {
        lapCalcOp = ""
        lapCalcMinutes = 0
        lapCalcSeconds = 0
        lapCalcPrevious = 0
        lapCalcCurrent = 0
        lapCalcExpression = ""
        lapCalcStartedWithNumber = false
    }

    private func recalcTotals() {
        var running = 0
        for i in laps.indices {
            running += laps[i].lapTime
            laps[i].totalTime = running
        }
        elapsedSeconds = running
    }

    private func normalizeTime(_ minutes: Int, _ seconds: Int) -> (m: Int, s: Int) {
        let total = minutes * 60 + seconds
        return (total / 60, total % 60)
    }

    private func applyOp(_ a: Int, op: String, rhs b: Int) -> Int {
        switch op {
        case "+": return a + b
        case "-": return max(0, a - b)
        case "*": return a * b
        case "/": return b != 0 ? a / b : a
        default: return a
        }
    }

    private func displayOp(_ op: String) -> String {
        switch op {
        case "*": return "×"
        case "/": return "÷"
        default: return op
        }
    }

    private func isTimeOp(_ op: String) -> Bool {
        op == "+" || op == "-"
    }
}
