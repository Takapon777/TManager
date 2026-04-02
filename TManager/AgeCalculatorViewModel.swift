//
//  AgeCalculatorViewModel.swift
//  TManager
//
//  Created by Hanoi on 2026/04/02.
//

import Foundation
import Combine

@MainActor
class AgeCalculatorViewModel: ObservableObject {
    @Published var ageTab: AgeTab = .western
    @Published var selectedYear: Int = 2000
    @Published var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var selectedDay: Int = Calendar.current.component(.day, from: Date())
    @Published var selectedEraYear: Int = 50
    @Published var selectedEraMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var selectedEraDay: Int = Calendar.current.component(.day, from: Date())
    @Published var ageResult: AgeResult?
    @Published var showAgeTable: Bool = false
    @Published var afterBirthday: Bool = true
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    enum AgeTab: String, CaseIterable {
        case western = "西暦"
        case showa = "昭和"
        case heisei = "平成"
        case reiwa = "令和"
        case taisho = "大正"
        case meiji = "明治"
    }

    struct AgeResult {
        let years: Int
        let months: Int
        let days: Int
        let totalDays: Int
        let totalMonths: Int
        let birthDate: Date
    }

    struct EraData {
        let start: Int
        let startMonth: Int
        let startDay: Int
        let end: Int?
        let endMonth: Int?
        let endDay: Int?
    }

    let eraMap: [String: EraData] = [
        "令和": EraData(start: 2019, startMonth: 5, startDay: 1, end: nil, endMonth: nil, endDay: nil),
        "平成": EraData(start: 1989, startMonth: 1, startDay: 8, end: 2019, endMonth: 4, endDay: 30),
        "昭和": EraData(start: 1926, startMonth: 12, startDay: 25, end: 1989, endMonth: 1, endDay: 7),
        "大正": EraData(start: 1912, startMonth: 7, startDay: 30, end: 1926, endMonth: 12, endDay: 24),
        "明治": EraData(start: 1868, startMonth: 1, startDay: 25, end: 1912, endMonth: 7, endDay: 29)
    ]

    var availableYears: [Int] {
        Array(1900...Calendar.current.component(.year, from: Date()))
    }

    var availableMonths: [Int] {
        Array(1...12)
    }

    var availableDays: [Int] {
        Array(1...31)
    }

    var eraYearRange: Range<Int> {
        guard let era = eraMap[ageTab.rawValue] else { return 1..<100 }
        if let end = era.end {
            return 1..<(end - era.start + 2)
        } else {
            return 1..<(Calendar.current.component(.year, from: Date()) - era.start + 2)
        }
    }

    func switchAgeTab(_ tab: AgeTab) {
        ageTab = tab
        ageResult = nil
        selectedMonth = Calendar.current.component(.month, from: Date())
        selectedDay = Calendar.current.component(.day, from: Date())
        selectedEraMonth = Calendar.current.component(.month, from: Date())
        selectedEraDay = Calendar.current.component(.day, from: Date())

        switch tab {
        case .showa: selectedEraYear = 50
        case .heisei: selectedEraYear = 15
        case .reiwa: selectedEraYear = 3
        case .taisho: selectedEraYear = 10
        case .meiji: selectedEraYear = 30
        default: break
        }
    }

    func reset() {
        ageResult = nil
        ageTab = .western
        selectedYear = 2000
        selectedMonth = Calendar.current.component(.month, from: Date())
        selectedDay = Calendar.current.component(.day, from: Date())
        selectedEraYear = 50
        selectedEraMonth = Calendar.current.component(.month, from: Date())
        selectedEraDay = Calendar.current.component(.day, from: Date())
        showAgeTable = false
        afterBirthday = true
    }

    func calculateAge() {
        var birthDate: Date?

        if ageTab == .western {
            guard selectedYear > 0, selectedMonth > 0, selectedDay > 0 else {
                showErrorMessage("すべての項目を選択してください。")
                return
            }
            var components = DateComponents()
            components.year = selectedYear
            components.month = selectedMonth
            components.day = selectedDay
            birthDate = Calendar.current.date(from: components)
        } else {
            let eraName = ageTab.rawValue
            guard let era = eraMap[eraName] else {
                showErrorMessage("元号データが見つかりません。")
                return
            }

            let westernYear = era.start + selectedEraYear - 1

            // Validate era range
            if westernYear == era.start,
               selectedEraMonth < era.startMonth ||
               (selectedEraMonth == era.startMonth && selectedEraDay < era.startDay) {
                showErrorMessage("入力された日付が元号の期間外です。")
                return
            }

            if let end = era.end,
               let endMonth = era.endMonth,
               let endDay = era.endDay {
                if westernYear > end ||
                   (westernYear == end && (selectedEraMonth > endMonth ||
                    (selectedEraMonth == endMonth && selectedEraDay > endDay))) {
                    showErrorMessage("入力された日付が元号の期間外です。")
                    return
                }
            }

            var components = DateComponents()
            components.year = westernYear
            components.month = selectedEraMonth
            components.day = selectedEraDay
            birthDate = Calendar.current.date(from: components)
        }

        guard let birth = birthDate else {
            showErrorMessage("日付の作成に失敗しました。")
            return
        }

        if birth > Date() {
            showErrorMessage("誕生日は今日より前の日付を選択してください。")
            return
        }

        let ageData = calculateDetailedAge(birth, today: Date())
        ageResult = AgeResult(
            years: ageData.years,
            months: ageData.months,
            days: ageData.days,
            totalDays: ageData.totalDays,
            totalMonths: ageData.totalMonths,
            birthDate: birth
        )
    }

    private func calculateDetailedAge(_ birthDate: Date, today: Date) -> (years: Int, months: Int, days: Int, totalDays: Int, totalMonths: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: birthDate, to: today)

        var years = components.year ?? 0
        var months = components.month ?? 0
        var days = components.day ?? 0

        if days < 0 {
            months -= 1
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: today)!
            let range = calendar.range(of: .day, in: .month, for: lastMonth)!
            days += range.count
        }

        if months < 0 {
            years -= 1
            months += 12
        }

        let totalDays = calendar.dateComponents([.day], from: birthDate, to: today).day ?? 0
        let totalMonths = years * 12 + months

        return (years, months, days, totalDays, totalMonths)
    }

    func getAgeForYear(_ year: Int) -> Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        let baseAge = currentYear - year
        return afterBirthday ? baseAge : baseAge - 1
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                showError = false
                errorMessage = nil
            }
        }
    }
}
