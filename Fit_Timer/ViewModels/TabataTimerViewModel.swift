import Foundation
import Combine

class TabataTimerViewModel: ObservableObject {
    @Published var state: TabataTimerState
    @Published var totalRounds: Int = 8
    private var timer: Timer?

    init() {
        self.state = TabataTimerState(
            workDuration: 20,
            restDuration: 10,
            totalRounds: 8,
            currentRound: 1,
            currentPhase: .stopped,
            timeRemaining: 20
        )
    }

    func setDurations(work: Int, rest: Int) {
        state.workDuration = work
        state.restDuration = rest
        state.totalRounds = totalRounds  // 외부 바인딩된 totalRounds 사용
        state.timeRemaining = work
    }

    func start() {
        // 멈춘 지점부터 시작하도록 조건 유지
        if state.currentPhase == .stopped {
            state.currentPhase = .work
            state.currentRound = 1
            state.timeRemaining = state.workDuration
            // ✅ 운동 시작 음성
            VoiceCue.shared.speak("운동을 시작합니다.")
        }
        runTimer()
    }

    func pause() {
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        state.currentPhase = .stopped
        state.currentRound = 1
        state.timeRemaining = state.workDuration
    }

    private func runTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.state.timeRemaining > 0 {
                self.state.timeRemaining -= 1
            } else {
                self.switchPhase()
            }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    private func switchPhase() {
        switch state.currentPhase {
        case .work:
            // work → rest 전환
            state.currentPhase = .rest
            state.timeRemaining = state.restDuration
            // ✅ 휴식 시작 음성
            VoiceCue.shared.speak("휴식을 시작합니다.")

        case .rest:
            // rest → 다음 work 또는 전체 종료
            if state.currentRound < state.totalRounds {
                state.currentRound += 1
                state.currentPhase = .work
                state.timeRemaining = state.workDuration
                // ✅ 운동 시작 음성
                VoiceCue.shared.speak("운동을 시작합니다.")
            } else {
                // ✅ 전체 완료 음성
                pause()
                VoiceCue.shared.speak("타바타를 모두 마쳤습니다.")
                reset()
            }

        case .stopped:
            break
        }
    }
}
