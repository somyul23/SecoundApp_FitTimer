import Foundation

/// 세트 타이머 화면의 상태/로직
final class SetTimerViewModel: ObservableObject {
    // MARK: - Published UI State
    @Published var workouts: [SetTimerWorkout] = []          // 실행할 운동 목록
    @Published private(set) var currentIndex: Int = 0        // 현재 운동 인덱스
    @Published var isResting: Bool = false                   // 휴식 중 여부
    @Published var restTimeRemaining: Int = 0                // 남은 휴식(초)

    @Published var showTransitionMessage = false             // 전환 메시지 표시
    @Published var transitionMessage = ""                    // 전환 메시지 내용

    @Published var didFinishAll: Bool = false                // ✅ 전체 완료 신호

    // 기록용: 루틴 제목(예: "상체 운동")
    private(set) var routineTitle: String?

    // MARK: - Private
    private var restTimer: Timer?
    private var restStartedAt: Date?
    private var pendingSetEventID: UUID? // 방금 완료한 세트 이벤트 ID(휴식 끝나면 actualRest 업데이트)

    // MARK: - Computed
    var currentWorkout: SetTimerWorkout? {
        guard currentIndex < workouts.count else { return nil }
        return workouts[currentIndex]
    }

    // MARK: - Configure
    func configure(initialWorkouts: [SetTimerWorkout], routineTitle: String? = nil) {
        self.workouts = initialWorkouts
        self.routineTitle = routineTitle
        self.currentIndex = 0
        self.isResting = false
        self.restTimeRemaining = 0
        self.pendingSetEventID = nil
        self.restStartedAt = nil
        self.didFinishAll = false
        self.showTransitionMessage = false
    }

    // MARK: - User Intent
    /// 세트 완료 버튼
    func markSetCompleted() {
        guard currentIndex < workouts.count else { return }

        // 현재 운동 스냅샷
        var w = workouts[currentIndex]

        // ✅ 1) 세트 이력 즉시 저장 (plannedRest 포함) → 이벤트 ID 반환
        let eventID = logSetCompleted(for: w)

        // ✅ 1-1) 위젯(주간 그래프) 즉시 갱신
        WidgetDataSync.publishWeeklyFromSetEvents(WorkoutRecordStore.shared.setEvents)

        // 2) 세트 카운트 + 1
        w.currentSet = min(w.currentSet + 1, w.totalSets)
        workouts[currentIndex] = w

        // 3) 분기
        let finishedThisWorkout = (w.currentSet >= w.totalSets)
        let hasNext = currentIndex < workouts.count - 1
        let plannedRest = w.restTime

        // ✅ 마지막 운동의 마지막 세트 → 즉시 종료 (중요: return!)
        if finishedThisWorkout && !hasNext {
            finishAll()
            return
        }

        // 이 운동은 끝났고 다음 운동이 있음 → 전환 메시지 후 다음 운동으로
        if finishedThisWorkout && hasNext {
            let next = workouts[currentIndex + 1]
            transitionMessage = "\"\(w.name)\" 완료\n다음: \"\(next.name)\""
            showTransitionMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self else { return }
                self.showTransitionMessage = false
                self.goToNextWorkout()
            }
            return
        }

        // 아직 세트 남음 → 휴식
        if plannedRest <= 0 {
            // 휴식 0초: 실제 휴식 0으로 곧바로 반영
            WorkoutRecordStore.shared.updateSetEventActualRest(id: eventID, actualRest: 0)
            endRestAndMaybeAdvance()
        } else {
            startRest(seconds: plannedRest, setEventID: eventID)
        }
    }

    /// 다음 운동으로
    func goToNextWorkout() {
        guard currentIndex < workouts.count - 1 else { return }
        currentIndex += 1
        isResting = false
        restTimer?.invalidate()
        restTimer = nil
        restTimeRemaining = 0
        restStartedAt = nil
        pendingSetEventID = nil
    }

    // MARK: - Rest
    private func startRest(seconds: Int, setEventID: UUID) {
        isResting = true
        restTimeRemaining = max(0, seconds)
        restStartedAt = Date()
        pendingSetEventID = setEventID

        restTimer?.invalidate()
        guard seconds > 0 else {
            endRestAndMaybeAdvance()
            return
        }

        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }
            guard self.restTimeRemaining > 0 else {
                timer.invalidate()
                self.restTimer = nil
                self.isResting = false
                self.endRestAndMaybeAdvance()
                return
            }
            self.restTimeRemaining -= 1
        }
        restTimer = t
        RunLoop.main.add(t, forMode: .common)
    }

    /// 휴식 종료 후 다음 단계로 이동(필요 시 실제 휴식시간 갱신)
    private func endRestAndMaybeAdvance() {
        // ✅ 방금 완료한 세트의 실제 휴식 시간 업데이트
        VoiceCue.shared.speak("휴식이 끝났습니다. 운동을 시작하세요.")
        VoiceCue.shared.tapHaptic()
        
        if let id = pendingSetEventID {
            let actual = max(0, Int(Date().timeIntervalSince(restStartedAt ?? Date())))
            WorkoutRecordStore.shared.updateSetEventActualRest(id: id, actualRest: actual)
            pendingSetEventID = nil
        }
        restStartedAt = nil
        isResting = false
        // 다음 세트로 진행은 뷰에서 버튼으로 계속 처리
    }

    // MARK: - Finish
    private func finishAll() {
        // 타이머 정리
        isResting = false
        restTimer?.invalidate()
        restTimer = nil
        restStartedAt = nil
        pendingSetEventID = nil

        // 인덱스를 범위 밖으로 밀어 UI가 완료 상태임을 알게 함
        currentIndex = workouts.count

        // 메시지 + 완료 신호
        showTransitionMessage = false
        transitionMessage = "모든 운동을 완료했어요 🎉"
        didFinishAll = true
        
        VoiceCue.shared.speak("모든 운동을 완료했습니다.")
        VoiceCue.shared.successHaptic()

        // 세션 기록 저장
        saveWorkoutRecord()
    }

    // MARK: - Logging
    /// 세트 완료 시점 기록 (plannedRest 포함) → 이벤트 ID 반환
    @discardableResult
    private func logSetCompleted(for w: SetTimerWorkout) -> UUID {
        let setNumber = min(w.currentSet + 1, w.totalSets) // currentSet은 완료된 갯수 → +1이 방금 완료되는 세트
        let title = routineTitle ?? workouts.map { $0.name }.joined(separator: ", ")
        let event = SetEvent(
            id: UUID(),
            date: Date(),
            routineName: title,
            exerciseName: w.name,
            setIndex: setNumber,
            plannedRest: w.restTime,
            actualRest: nil
        )
        WorkoutRecordStore.shared.addSetEvent(event)
        return event.id
    }

    private func saveWorkoutRecord() {
        let totalSets = workouts.reduce(0) { $0 + $1.totalSets }
        let completedSets = workouts.reduce(0) { $0 + $1.currentSet }
        let title = routineTitle ?? workouts.map { $0.name }.joined(separator: ", ")

        let record = WorkoutRecord(
            id: UUID(),
            date: Date(),
            routineName: title,
            totalSets: totalSets,
            completedSets: completedSets,
            notes: ""
        )
        WorkoutRecordStore.shared.add(record)
    }

    deinit { restTimer?.invalidate() }
}
