import Foundation

struct SetTimerWorkout: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var totalSets: Int
    var restTime: Int    // 초
    var currentSet: Int = 0
}
