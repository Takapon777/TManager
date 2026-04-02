//
//  AgeCalculatorView.swift
//  TManager
//
//  Created by Hanoi on 2026/04/02.
//

import SwiftUI

struct AgeCalculatorView: View {
    @StateObject private var viewModel = AgeCalculatorViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.showAgeTable {
                    AgeTableView(viewModel: viewModel)
                } else {
                    mainContent
                }

                // Error Popup
                if viewModel.showError, let message = viewModel.errorMessage {
                    VStack {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(message)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.red)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        Spacer()
                    }
                    .padding(.top, 60)
                    .transition(.move(edge: .top))
                    .animation(.easeInOut, value: viewModel.showError)
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

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Birth Date Input Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("誕生日入力")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Spacer()

                        Button(action: { viewModel.showAgeTable = true }) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Color(.systemGray6).opacity(0.5))
                                .cornerRadius(8)
                        }
                    }

                    // Era Tabs
                    HStack(spacing: 8) {
                        ForEach([AgeCalculatorViewModel.AgeTab.western, .showa, .heisei, .reiwa, .taisho, .meiji], id: \.self) { tab in
                            Button(action: { viewModel.switchAgeTab(tab) }) {
                                Text(tab.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(viewModel.ageTab == tab ? .white : .gray)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(viewModel.ageTab == tab ? .orange : Color(.systemGray6).opacity(0.3))
                                    .cornerRadius(8)
                            }
                        }
                    }

                    // Date Pickers
                    HStack(spacing: 12) {
                        // Year Picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("年")
                                .font(.caption)
                                .foregroundStyle(.gray)

                            if viewModel.ageTab == .western {
                                Picker("年", selection: Binding(
                                    get: { viewModel.selectedYear },
                                    set: { viewModel.selectedYear = $0 }
                                )) {
                                    ForEach(viewModel.availableYears, id: \.self) { year in
                                        Text("\(year)").tag(year)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 100)
                                .clipped()
                            } else {
                                Picker("年", selection: Binding(
                                    get: { viewModel.selectedEraYear },
                                    set: { viewModel.selectedEraYear = $0 }
                                )) {
                                    ForEach(viewModel.eraYearRange, id: \.self) { year in
                                        Text("\(year)").tag(year)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 100)
                                .clipped()
                            }
                        }

                        // Month Picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("月")
                                .font(.caption)
                                .foregroundStyle(.gray)

                            Picker("月", selection: Binding(
                                get: { viewModel.ageTab == .western ? viewModel.selectedMonth : viewModel.selectedEraMonth },
                                set: {
                                    if viewModel.ageTab == .western {
                                        viewModel.selectedMonth = $0
                                    } else {
                                        viewModel.selectedEraMonth = $0
                                    }
                                }
                            )) {
                                ForEach(viewModel.availableMonths, id: \.self) { month in
                                    Text("\(month)").tag(month)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .clipped()
                        }
                        .frame(width: 60)

                        // Day Picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("日")
                                .font(.caption)
                                .foregroundStyle(.gray)

                            Picker("日", selection: Binding(
                                get: { viewModel.ageTab == .western ? viewModel.selectedDay : viewModel.selectedEraDay },
                                set: {
                                    if viewModel.ageTab == .western {
                                        viewModel.selectedDay = $0
                                    } else {
                                        viewModel.selectedEraDay = $0
                                    }
                                }
                            )) {
                                ForEach(viewModel.availableDays, id: \.self) { day in
                                    Text("\(day)").tag(day)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .clipped()
                        }
                        .frame(width: 60)
                    }

                    // Calculate / Reset Button
                    Button(action: {
                        if viewModel.ageResult != nil {
                            viewModel.reset()
                        } else {
                            viewModel.calculateAge()
                        }
                    }) {
                        Text(viewModel.ageResult != nil ? "リセット" : "年齢を計算")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(viewModel.ageResult != nil ? Color(.systemGray4) : .orange)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.2))
                .cornerRadius(16)
                .padding(.horizontal)

                // Result Card
                if let result = viewModel.ageResult {
                    VStack(spacing: 16) {
                        // Big age display
                        Text("\(result.years)歳")
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(.orange)

                        Text(verbatim: "\(Calendar.current.component(.year, from: result.birthDate))年\(Calendar.current.component(.month, from: result.birthDate))月\(Calendar.current.component(.day, from: result.birthDate))日生まれ")
                            .font(.subheadline)
                            .foregroundStyle(.gray)

                        Divider()
                            .background(Color(.systemGray4))

                        // Details
                        HStack {
                            Text("詳細年齢")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text("\(result.years)年\(result.months)か月\(result.days)日")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.white)
                        }

                        HStack {
                            Text("総日数")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(verbatim: "\(result.totalDays)日")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.2))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }

                Spacer(minLength: 20)
            }
            .padding(.top, 16)
        }
    }
}

// MARK: - Age Table View
struct AgeTableView: View {
    @ObservedObject var viewModel: AgeCalculatorViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("年齢早見表")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Spacer()

                Button(action: { viewModel.showAgeTable = false }) {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(8)
                }
            }
            .padding()

            // Toggle
            HStack(spacing: 12) {
                Text("誕生日前")
                    .font(.subheadline)
                    .foregroundStyle(.gray)

                Toggle("", isOn: Binding(
                    get: { viewModel.afterBirthday },
                    set: { viewModel.afterBirthday = $0 }
                ))
                .labelsHidden()
                .tint(.orange)

                Text("誕生日後")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            // Table Header
            HStack {
                Text("生まれた年")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
                Spacer()
                Text("年齢")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.systemGray5).opacity(0.3))

            // Table Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach((1900...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                        HStack {
                            Text(verbatim: "\(year)年")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(viewModel.getAgeForYear(year))歳")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.orange)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        Divider()
                            .background(Color(.systemGray6).opacity(0.3))
                    }
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    AgeCalculatorView()
        .preferredColorScheme(.dark)
}
