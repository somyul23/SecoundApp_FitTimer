import Foundation
import WidgetKit

// ⚠️ 이 파일 안에서는 Shared를 만들지 않습니다.
// App/Widget 양쪽 Capabilities에 설정한 App Group을 아래에 그대로 적어주세요.
enum AppGroup {
    static let id = "group.com.yourco.fittimer"
}

enum WidgetDataSync {

    // MARK: - UserDefaults(App Group)
    private static var suite: UserDefaults {
        UserDefaults(suiteName: AppGroup.id) ?? .standard
    }

    // MARK: - 1) 주간 그래프 동기화 (지난주/이번주, 월~일 7칸)
    static func publishWeeklyFromSetEvents(_ events: [SetEvent]) {
        let cal = Calendar(identifier: .iso8601)
        let today = Date()

        // 이번 주 시작(월요일 00:00 기준)
        let startThisWeek: Date = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let endThisWeek:   Date = cal.date(byAdding: .day, value: 7, to: startThisWeek)!
        let startLastWeek: Date = cal.date(byAdding: .day, value: -7, to: startThisWeek)!
        let endLastWeek:   Date = startThisWeek

        // 0=월 ... 6=일
        func mondayIndex(for d: Date) -> Int {
            let wd = cal.component(.weekday, from: d) // 1=일 ... 7=토
            let map: [Int] = [0, 6, 0, 1, 2, 3, 4, 5] // 일→6, 월→0 ...
            let i = max(1, min(7, wd))
            return map[i]
        }

        var this: [Int] = Array(repeating: 0, count: 7)
        var last: [Int] = Array(repeating: 0, count: 7)

        for e in events {
            let d = e.date
            if d >= startThisWeek && d < endThisWeek {
                this[mondayIndex(for: d)] += 1
            } else if d >= startLastWeek && d < endLastWeek {
                last[mondayIndex(for: d)] += 1
            }
        }

        suite.set(this, forKey: "widget_weekly_this")
        suite.set(last, forKey: "widget_weekly_last")
        WidgetCenter.shared.reloadTimelines(ofKind: "WeeklyChartWidget")
    }

    // MARK: - 2) 루틴 리스트 동기화 (Large 위젯에 사용)
    struct RoutineCard: Codable, Hashable {
        let id: String
        let name: String
        let sets: Int
    }

    /// App 쪽의 @AppStorage("routines_v2_json") 바이트를 그대로 넣어주세요.
    static func publishRoutinesFromBlob(_ blob: Data) {
        // App 파일의 PersistedRoutine/PersistedExercise에 의존하지 않도록
        // 여기서만 사용할 디코딩용 타입을 로컬로 정의합니다.
        struct PExercise: Codable { let id: UUID; let name: String; let sets: Int; let restTime: Int }
        struct PRoutine:  Codable { let id: UUID; let name: String; let exercises: [PExercise] }

        guard !blob.isEmpty,
              let decoded: [PRoutine] = try? JSONDecoder().decode([PRoutine].self, from: blob)
        else {
            suite.set(Data(), forKey: "widget_routines")
            WidgetCenter.shared.reloadTimelines(ofKind: "RoutineListWidget")
            return
        }

        let items: [RoutineCard] = decoded.map {
            RoutineCard(
                id: $0.id.uuidString,
                name: $0.name,
                sets: $0.exercises.reduce(0) { $0 + $1.sets }
            )
        }

        if let data = try? JSONEncoder().encode(items) {
            suite.set(data, forKey: "widget_routines")
            WidgetCenter.shared.reloadTimelines(ofKind: "RoutineListWidget")
        }
    }
}
