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

    private var timer: Timer?

    struct Lap: Identifiable {
        let id: Int
        let lapTime: Int
        let totalTime: Int
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
    }

    func addLap() {
        let lapTime = laps.isEmpty ? elapsedSeconds : elapsedSeconds - (laps.last?.totalTime ?? 0)
        let newLap = Lap(
            id: laps.count + 1,
            lapTime: lapTime,
            totalTime: elapsedSeconds
        )
        laps.append(newLap)
    }
}
