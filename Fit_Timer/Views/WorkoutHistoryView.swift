import SwiftUI
import Charts

struct WorkoutHistoryView: View {
    @ObservedObject var store = WorkoutRecordStore.shared

    enum Tab: String, CaseIterable, Identifiable {
        case overview = "개요"
        case detail   = "목록"
        var id: String { rawValue }
    }

    @State private var tab: Tab = .overview

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                ForEach(Tab.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)

            if tab == .overview {
                OverviewChartView(setEvents: store.setEvents)
            } else {
                RoutineExerciseListView(setEvents: store.setEvents)
            }
        }
        .navigationTitle("운동 기록")
    }
}

// MARK: - 개요 탭
private struct OverviewChartView: View {
    let setEvents: [SetEvent]

    private let weekdayKOR = ["월","화","수","목","금","토","일"]

    private struct Point: Identifiable {
        let id = UUID()
        let index: Int
        let value: Int
        let series: String // "지난주" / "이번주"
    }

    private var weeklyBins: (this: [Int], last: [Int], totalThis: Int, totalLast: Int) {
        let cal = Calendar.current
        let today = Date()
        let startThisWeek = cal.startOfWeek(for: today)
        let startLastWeek = cal.date(byAdding: .day, value: -7, to: startThisWeek)!
        let endThisWeek   = cal.date(byAdding: .day, value: 7, to: startThisWeek)!
        let endLastWeek   = startThisWeek

        var thisWeek = Array(repeating: 0, count: 7)
        var lastWeek = Array(repeating: 0, count: 7)

        for e in setEvents {
            if e.date >= startThisWeek && e.date < endThisWeek {
                let idx = cal.mondayBasedWeekdayIndex(for: e.date)
                thisWeek[idx] += 1
            } else if e.date >= startLastWeek && e.date < endLastWeek {
                let idx = cal.mondayBasedWeekdayIndex(for: e.date)
                lastWeek[idx] += 1
            }
        }

        return (this: thisWeek,
                last: lastWeek,
                totalThis: thisWeek.reduce(0, +),
                totalLast: lastWeek.reduce(0, +))
    }

    private var chartPoints: [Point] {
        let last = (0..<7).map { Point(index: $0, value: weeklyBins.last[$0], series: "지난주") }
        let this = (0..<7).map { Point(index: $0, value: weeklyBins.this[$0], series: "이번주") }
        return last + this
    }

    private var maxY: Int {
        max((weeklyBins.this + weeklyBins.last).max() ?? 0, 5).roundedUp(step: 2)
    }

    private var streakDays: Int {
        let cal = Calendar.current
        let daysWithActivity: Set<Date> = Set(setEvents.map { cal.startOfDay(for: $0.date) })
        var streak = 0
        var day = cal.startOfDay(for: Date())
        while daysWithActivity.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    private var top5Exercises: [(name: String, count: Int)] {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -30, to: Date())!
        var dict: [String: Int] = [:]
        for e in setEvents where e.date >= cutoff {
            dict[e.exerciseName, default: 0] += 1
        }
        return Array(dict.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }.prefix(5))
    }

    private struct DayCell: Identifiable {
        let id = UUID()
        let date: Date?
        let count: Int
    }

    private var monthCells: (cells: [DayCell], maxCount: Int, title: String) {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        let firstOfMonth = cal.date(from: comps)!
        let range = cal.range(of: .day, in: .month, for: firstOfMonth)!
        let daysInMonth = range.count
        let startWeekdayIndex = cal.mondayBasedWeekdayIndex(for: firstOfMonth)

        var countsByDay = Array(repeating: 0, count: daysInMonth + 1)
        for e in setEvents {
            let d = cal.startOfDay(for: e.date)
            if let day = cal.dateComponents([.day], from: d).day,
               cal.isDate(d, equalTo: firstOfMonth, toGranularity: .month),
               (1...daysInMonth).contains(day) {
                countsByDay[day] += 1
            }
        }

        let maxCount = max(countsByDay.max() ?? 0, 1)
        var cells: [DayCell] = []

        if startWeekdayIndex > 0 {
            cells.append(contentsOf: Array(repeating: DayCell(date: nil, count: 0), count: startWeekdayIndex))
        }
        for day in 1...daysInMonth {
            let date = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth)!
            cells.append(DayCell(date: date, count: countsByDay[day]))
        }

        let title = firstOfMonth.formatted(.dateTime.year().month(.wide))
        return (cells, maxCount, title)
    }

    private func heatColor(for count: Int, max: Int) -> Color {
        guard count > 0 else { return Color.secondary.opacity(0.12) }
        let t = max > 0 ? min(1.0, Double(count) / Double(max)) : 0
        return Color.green.opacity(0.25 + 0.75 * t)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 12) {
                    StreakCard(streak: streakDays)
                    MetricCard(title: "이번 주 세트", value: weeklyBins.totalThis)
                    DeltaCard(thisWeek: weeklyBins.totalThis, lastWeek: weeklyBins.totalLast)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)

                // 차트
                Chart {
                    ForEach(chartPoints) { p in
                        LineMark(x: .value("요일", p.index),
                                 y: .value("세트", p.value))
                        .foregroundStyle(by: .value("주차", p.series))
                        PointMark(x: .value("요일", p.index),
                                  y: .value("세트", p.value))
                        .foregroundStyle(by: .value("주차", p.series))
                    }
                }
                .chartForegroundStyleScale(["지난주": .gray, "이번주": .green])
                .chartXAxis {
                    AxisMarks(values: Array(0..<7)) { value in
                        AxisGridLine()
                        AxisValueLabel(weekdayKOR[(value.as(Int.self) ?? 0) % 7])
                    }
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .chartYScale(domain: 0...maxY)
                .frame(height: 220)
                .padding(.horizontal)

                // Top 5
                VStack(alignment: .leading, spacing: 8) {
                    Text("운동 TOP 5 (최근 30일)")
                        .font(.headline)
                        .padding(.horizontal)
                    if top5Exercises.isEmpty {
                        Text("기록이 부족해요. 세트 완료를 기록해보세요!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(Array(top5Exercises.enumerated()), id: \.offset) { i, item in
                            HStack {
                                Text("\(i+1). \(item.name)")
                                Spacer()
                                Text("\(item.count)세트")
                                    .monospacedDigit()
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(.thinMaterial)
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                }

                // 히트맵
                VStack(alignment: .leading, spacing: 10) {
                    Text(monthCells.title).font(.headline).padding(.horizontal)
                    HStack {
                        ForEach(["월","화","수","목","금","토","일"], id: \.self) {
                            Text($0).font(.caption2).foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 8)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                        ForEach(monthCells.cells) { cell in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(heatColor(for: cell.count, max: monthCells.maxCount))
                                .frame(height: 28)
                                .overlay {
                                    if let date = cell.date {
                                        Text("\(Calendar.current.component(.day, from: date))")
                                            .font(.caption2)
                                            .foregroundColor(cell.count == 0 ? .secondary : .white)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - 목록 탭 (삭제 기능 추가됨)
private struct RoutineExerciseListView: View {
    let setEvents: [SetEvent]
    @State private var showDeleteAlert = false
    @State private var pendingDelete: (routine: String, exercise: String)? = nil

    struct ExerciseCount: Identifiable {
        var id: String { exerciseName }
        let exerciseName: String
        let count: Int
        let lastDate: Date?
    }
    struct RoutineSection: Identifiable {
        var id: String { routineName }
        let routineName: String
        let total: Int
        let exercises: [ExerciseCount]
    }

    private var todaysEvents: [SetEvent] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return setEvents.filter { $0.date >= start && $0.date < end }
    }

    private var sections: [RoutineSection] {
        var map: [String: [String: (count: Int, last: Date?)]] = [:]
        for e in todaysEvents {
            var exMap = map[e.routineName, default: [:]]
            let cur = exMap[e.exerciseName] ?? (0, nil)
            let newCount = cur.count + 1
            let newLast = max(cur.last ?? .distantPast, e.date)
            exMap[e.exerciseName] = (newCount, newLast)
            map[e.routineName] = exMap
        }
        return map.map { (routine, exMap) in
            let exercises = exMap.map { (name, meta) in
                ExerciseCount(exerciseName: name, count: meta.count, lastDate: meta.last)
            }.sorted { $0.count > $1.count }
            let total = exercises.reduce(0) { $0 + $1.count }
            return RoutineSection(routineName: routine, total: total, exercises: exercises)
        }.sorted { $0.total > $1.total }
    }

    var body: some View {
        if sections.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("오늘 기록이 없어요")
                    .font(.headline)
                Text("세트 완료를 기록하면 여기에서 바로 볼 수 있어요.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 40)
        } else {
            List {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.exercises) { ex in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ex.exerciseName).font(.headline)
                                    if let last = ex.lastDate {
                                        Text(last.formatted(date: .omitted, time: .shortened))
                                            .font(.caption).foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Text("\(ex.count)세트")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundColor(.secondary)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    pendingDelete = (section.routineName, ex.exerciseName)
                                    showDeleteAlert = true
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text(section.routineName)
                            Spacer()
                            Text("\(section.total)세트")
                                .font(.subheadline.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .alert("삭제 확인", isPresented: $showDeleteAlert) {
                Button("삭제", role: .destructive) {
                    if let p = pendingDelete {
                        WorkoutRecordStore.shared.deleteTodayRecords(for: p.routine, exerciseName: p.exercise)
                    }
                }
                Button("취소", role: .cancel) { }
            } message: {
                if let p = pendingDelete {
                    Text("‘\(p.exercise)’ 운동 기록을 오늘 날짜 기준으로 삭제하시겠습니까?")
                }
            }
        }
    }
}

// MARK: - 카드 뷰들
private struct MetricCard: View { let title: String; let value: Int
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text("\(value)").font(.title2.bold()).monospacedDigit()
        }.frame(maxWidth: .infinity, alignment: .leading)
            .padding().background(.thinMaterial).cornerRadius(14)
    }
}

private struct DeltaCard: View { let thisWeek: Int; let lastWeek: Int
    var diff: Int { thisWeek - lastWeek }
    var body: some View {
        let up = diff >= 0
        let color: Color = up ? .green : .red
        VStack(alignment: .leading) {
            Text("지난 주 대비").font(.caption).foregroundColor(.secondary)
            HStack {
                Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                Text("\(abs(diff))")
            }.font(.title2.bold()).foregroundColor(color)
        }.frame(maxWidth: .infinity, alignment: .leading)
            .padding().background(.thinMaterial).cornerRadius(14)
    }
}

private struct StreakCard: View { let streak: Int
    var body: some View {
        VStack(alignment: .leading) {
            Text("연속 달성").font(.caption).foregroundColor(.secondary)
            HStack {
                Text("🔥").font(.title2)
                Text("\(streak)일").font(.title2.bold()).monospacedDigit()
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
            .padding().background(.thinMaterial).cornerRadius(14)
    }
}

// MARK: - Helpers
private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        var cal = self; cal.firstWeekday = 2
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps)!
    }
    func mondayBasedWeekdayIndex(for date: Date) -> Int {
        var cal = self; cal.firstWeekday = 2
        let wd = cal.component(.weekday, from: date)
        let map = [0,6,0,1,2,3,4,5]
        return map[max(1,min(7,wd))]
    }
}
private extension Array where Element == Int {
    static func + (lhs: [Int], rhs: [Int]) -> [Int] { zip(lhs, rhs).map(+) }
}
private extension BinaryInteger {
    func roundedUp(step: Int) -> Int {
        guard step > 0 else { return Int(self) }
        let v = Int(self); let r = v % step
        return r == 0 ? v : v + (step - r)
    }
}
