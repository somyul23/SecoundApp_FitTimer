
import Foundation
import ActivityKit

@available(iOS 16.1, *)
struct WorkoutActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        enum Phase: String, Codable, Hashable { case work, rest, stopped }

        var phase: Phase
        /// 잠금화면 카운트다운(있을 때만 표시)
        var remaining: ClosedRange<Date>?

        /// 세트 타이머용
        var setCurrent: Int?
        var setTotal: Int?
        /// 🔹 세트 타이머 휴식 길이(잠금화면에서 세트완료 시 사용)
        var restPerSet: Int?

        /// 타바타용
        var roundCurrent: Int?
        var roundTotal: Int?
    }

    enum Mode: String, Codable, Hashable { case setTimer, tabata }

    var mode: Mode
    var title: String
    var subtitle: String?
}
