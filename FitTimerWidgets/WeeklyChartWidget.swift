import WidgetKit
import SwiftUI
import Charts

struct WeeklyEntry: TimelineEntry {
    let date: Date
    let this: [Int]
    let last: [Int]
}

struct WeeklyProvider: TimelineProvider {
    func placeholder(in: Context) -> WeeklyEntry {
        WeeklyEntry(date: .now, this: [1,2,3,2,4,1,0], last: [0,1,1,2,2,1,0])
    }
    func getSnapshot(in: Context, completion: @escaping (WeeklyEntry) -> Void) {
        completion(load())
    }
    func getTimeline(in: Context, completion: @escaping (Timeline<WeeklyEntry>) -> Void) {
        completion(Timeline(entries: [load()], policy: .after(Date().addingTimeInterval(60*15))))
    }
    // getTimeline/placeholder 그대로, load()만 확인
    private func load() -> WeeklyEntry {
        let ud = UserDefaults(suiteName: Shared.appGroupId) ?? .standard
        let this = (ud.array(forKey: "widget_weekly_this") as? [Int]) ?? Array(repeating: 0, count: 7)
        let last = (ud.array(forKey: "widget_weekly_last") as? [Int]) ?? Array(repeating: 0, count: 7)
        return WeeklyEntry(date: .now, this: this, last: last)
    }

}

struct WeeklyChartWidgetView: View {
    let entry: WeeklyEntry
    private let days = ["월","화","수","목","금","토","일"]

    private struct Point: Identifiable {
        let id = UUID()
        let x: Int
        let y: Int
        let series: String // "지난주" / "이번주"
    }
    private var points: [Point] {
        let last = entry.last.enumerated().map { Point(x: $0.offset, y: $0.element, series: "지난주") }
        let this = entry.this.enumerated().map { Point(x: $0.offset, y: $0.element, series: "이번주") }
        return last + this
    }

    // ✅ 공통 콘텐츠 뷰
    @ViewBuilder
    private var content: some View {
        Chart {
            ForEach(points) { p in
                LineMark(x: .value("요일", p.x), y: .value("세트", p.y))
                    .interpolationMethod(.linear)
                    .foregroundStyle(by: .value("주차", p.series))
                PointMark(x: .value("요일", p.x), y: .value("세트", p.y))
                    .foregroundStyle(by: .value("주차", p.series))
                    .symbolSize(18)
            }
        }
        .chartForegroundStyleScale(["지난주": .gray, "이번주": .green])
        .chartXAxis {
            AxisMarks(values: Array(0..<7)) { v in
                AxisValueLabel(days[(v.as(Int.self) ?? 0) % 7])
            }
        }
        .chartLegend(.hidden)
        .padding(.horizontal, 8)
        .widgetURL(URL(string: "fittimer://open")!)
    }

    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content
                // ✅ iOS 17+: 위젯 배경 채택 (안내 문구 제거)
                .containerBackground(for: .widget) {
                    // 투명 느낌 유지하고 싶으면 Color.clear, 기본 틴트 쓰고 싶으면 .thinMaterial 등
                    Color.clear
                }
        } else {
            content
        }
    }
}

struct WeeklyChartWidget: Widget {
    let kind = "WeeklyChartWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyProvider()) { entry in
            WeeklyChartWidgetView(entry: entry)
        }
        .configurationDisplayName("주간 운동량")
        .description("지난주 vs 이번주 세트 수 비교")
        .supportedFamilies([.systemMedium])
    }
}

