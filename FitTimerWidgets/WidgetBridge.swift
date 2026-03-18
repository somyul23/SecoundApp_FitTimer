import Foundation
import WidgetKit

enum WidgetBridge {
    private static var suite: UserDefaults {
        UserDefaults(suiteName: Shared.appGroupId) ?? .standard
    }

    // 월~일 7칸: 이번주/지난주
    static func publishWeekly(thisWeek: [Int], lastWeek: [Int]) {
        suite.set(thisWeek, forKey: "widget_weekly_this")
        suite.set(lastWeek, forKey: "widget_weekly_last")
        WidgetCenter.shared.reloadTimelines(ofKind: "WeeklyChartWidget")
    }

    struct RoutineCard: Codable, Hashable {
        let id: String
        let name: String
        let sets: Int
    }

    static func publishRoutines(_ routines: [RoutineCard]) {
        if let data = try? JSONEncoder().encode(routines) {
            suite.set(data, forKey: "widget_routines")
            WidgetCenter.shared.reloadTimelines(ofKind: "RoutineListWidget")
        }
    }
}
