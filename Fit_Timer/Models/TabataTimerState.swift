import Foundation

enum Phase {
    case work
    case rest
    case stopped
}

struct TabataTimerState {
    var workDuration: Int // 초 단위
    var restDuration: Int // 초 단위
    var totalRounds: Int
    var currentRound: Int
    var currentPhase: Phase
    var timeRemaining: Int
}
