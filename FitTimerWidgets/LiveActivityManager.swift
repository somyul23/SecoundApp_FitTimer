import Foundation
import ActivityKit

@available(iOS 16.1, *)
@MainActor
enum LiveActivityManager {
    private static var activity: Activity<WorkoutActivityAttributes>?

    // MARK: Set Timer
    static func startSetTimer(title: String, subtitle: String?, setCurrent: Int, setTotal: Int, restPerSet: Int) {
        let attrs = WorkoutActivityAttributes(mode: .setTimer, title: title, subtitle: subtitle)
        let state = WorkoutActivityAttributes.ContentState(
            phase: .work, remaining: nil,
            setCurrent: setCurrent, setTotal: setTotal, restPerSet: restPerSet,
            roundCurrent: nil, roundTotal: nil
        )
        activity = try? Activity.request(attributes: attrs, contentState: state)
    }

    static func updateSetTimer(phase: WorkoutActivityAttributes.ContentState.Phase,
                               setCurrent: Int, setTotal: Int, seconds: Int?) {
        guard let act = activity else { return }
        let now = Date()
        let range: ClosedRange<Date>? = (seconds ?? 0) > 0 ? (now ... now.addingTimeInterval(TimeInterval(seconds!))) : nil
        var s = act.contentState
        s.phase = phase; s.remaining = range; s.setCurrent = setCurrent; s.setTotal = setTotal
        Task { try? await act.update(using: s) }
    }

    /// 잠금화면 즉시 반영: 세트 완료 → 다음 세트 휴식 or 종료
    static func advanceSetTimerImmediate() {
        for act in Activity<WorkoutActivityAttributes>.activities where act.attributes.mode == .setTimer {
            var s = act.contentState
            guard let cur = s.setCurrent, let tot = s.setTotal else { continue }
            if cur < tot {
                s.setCurrent = cur + 1
                s.phase = .rest
                let rest = s.restPerSet ?? 0
                let now = Date()
                s.remaining = rest > 0 ? (now ... now.addingTimeInterval(TimeInterval(rest))) : nil
                Task { try? await act.update(using: s) }
            } else {
                Task { try? await act.end(dismissalPolicy: .immediate) }
            }
        }
    }

    // MARK: Tabata
    static func startTabata(title: String, roundCurrent: Int, roundTotal: Int,
                            phase: WorkoutActivityAttributes.ContentState.Phase, seconds: Int) {
        let attrs = WorkoutActivityAttributes(mode: .tabata, title: title, subtitle: nil)
        let now = Date()
        let range: ClosedRange<Date>? = seconds > 0 ? (now ... now.addingTimeInterval(TimeInterval(seconds))) : nil
        let state = WorkoutActivityAttributes.ContentState(
            phase: phase, remaining: range,
            setCurrent: nil, setTotal: nil, restPerSet: nil,
            roundCurrent: roundCurrent, roundTotal: roundTotal
        )
        activity = try? Activity.request(attributes: attrs, contentState: state)
    }

    static func updateTabata(roundCurrent: Int, roundTotal: Int,
                             phase: WorkoutActivityAttributes.ContentState.Phase, seconds: Int) {
        guard let act = activity else { return }
        let now = Date()
        let range: ClosedRange<Date>? = seconds > 0 ? (now ... now.addingTimeInterval(TimeInterval(seconds))) : nil
        var s = act.contentState
        s.phase = phase; s.remaining = range; s.roundCurrent = roundCurrent; s.roundTotal = roundTotal
        Task { try? await act.update(using: s) }
    }

    /// 잠금화면 즉시 반영: 타바타 일시정지
    static func pauseTabataImmediate() {
        for act in Activity<WorkoutActivityAttributes>.activities where act.attributes.mode == .tabata {
            var s = act.contentState
            s.phase = .stopped; s.remaining = nil
            Task { try? await act.update(using: s) }
        }
    }

    // MARK: Common
    static func end() {
        if let act = activity {
            Task { try? await act.end(dismissalPolicy: .immediate) }
        }
        activity = nil
    }
}
