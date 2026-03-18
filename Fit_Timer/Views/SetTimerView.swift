import SwiftUI

// ✅ 루틴리스트까지 닫기 위한 노티키
extension Notification.Name {
    static let setTimerDidFinishAll = Notification.Name("setTimerDidFinishAll")
}

struct SetTimerView: View {
    // 루틴에서 넘겨받을 초기 운동 목록 + 루틴 제목
    var initialWorkouts: [SetTimerWorkout] = []
    var routineTitle: String? = nil

    @StateObject private var viewModel = SetTimerViewModel()

    @Environment(\.dismiss) private var dismiss           // 한 단계 pop
    @State private var didAutoPop = false                 // 중복 pop 방지

    // 🔔 Live Activity 자동 관리
    @State private var didStartLiveActivity = false

    var body: some View {
        VStack(spacing: 24) {
            if viewModel.isResting {
                Text("⏳ 휴식 중")
                    .font(.largeTitle).bold()
                Text("\(viewModel.restTimeRemaining)초 남음")
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            } else if let w = viewModel.currentWorkout {
                // 진행 중
                Text(w.name)
                    .font(.title2.bold())
                Text("\(w.currentSet)/\(w.totalSets) 세트 완료")
                    .foregroundColor(.secondary)

                Button {
                    viewModel.markSetCompleted()    // ✅ 세트 완료 → 즉시 이력 저장 & 분기
                } label: {
                    Text("세트 완료")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 12)
            } else {
                // 모든 운동 완료 상태(자동 pop 전 잠깐 보일 수 있음)
                Text("🏁 모든 운동을 완료했습니다!")
                    .font(.title)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        // 전환/완료 메시지 오버레이
        .overlay(
            Group {
                if viewModel.showTransitionMessage || viewModel.didFinishAll {
                    VStack {
                        Text(viewModel.didFinishAll ? "모든 운동을 완료했습니다!" : viewModel.transitionMessage)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                }
            }
        )
        .animation(.easeInOut(duration: 0.25), value: viewModel.showTransitionMessage)
        .animation(.easeInOut(duration: 0.25), value: viewModel.didFinishAll)
        .onAppear {
            viewModel.configure(initialWorkouts: initialWorkouts, routineTitle: routineTitle)

            // ✅ 화면 진입 시 Live Activity 자동 시작 (work 상태, 카운트다운 없음)
            if #available(iOS 16.1, *), !didStartLiveActivity, let w = viewModel.currentWorkout {
                LiveActivityManager.startSetTimer(
                    title: routineTitle ?? "세트 타이머",
                    subtitle: w.name,
                    setCurrent: w.currentSet,
                    setTotal: w.totalSets,
                    restPerSet: w.restTime  
                )
                didStartLiveActivity = true
            }
        }
        // ✅ 세트/운동 전환에 맞춰 Live Activity 업데이트
        .onChange(of: viewModel.isResting) { isRest in
            guard #available(iOS 16.1, *), didStartLiveActivity, let w = viewModel.currentWorkout else { return }
            if isRest {
                LiveActivityManager.updateSetTimer(
                    phase: .rest,
                    setCurrent: w.currentSet,
                    setTotal: w.totalSets,
                    seconds: viewModel.restTimeRemaining
                )
            } else {
                LiveActivityManager.updateSetTimer(
                    phase: .work,
                    setCurrent: w.currentSet,
                    setTotal: w.totalSets,
                    seconds: nil
                )
            }
        }
        // ✅ 세트가 진행되어 currentWorkout이 바뀔 때도 제목/세트 수 갱신
        .onChange(of: viewModel.currentWorkout?.currentSet) { _ in
            guard #available(iOS 16.1, *), didStartLiveActivity, let w = viewModel.currentWorkout else { return }
            // work 상태에서 세트 카운트만 갱신
            if !viewModel.isResting {
                LiveActivityManager.updateSetTimer(
                    phase: .work,
                    setCurrent: w.currentSet,
                    setTotal: w.totalSets,
                    seconds: nil
                )
            }
        }
        // ✅ 완료 신호 감지 → 1초 표시 → 타이머뷰 pop → 루틴리스트도 pop(홈으로) + Live Activity 종료
        .onChange(of: viewModel.didFinishAll) {
            guard viewModel.didFinishAll, !didAutoPop else { return }
            if #available(iOS 16.1, *), didStartLiveActivity {
                LiveActivityManager.end()
                didStartLiveActivity = false
            }
            didAutoPop = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss() // 1) SetTimerView → pop (루틴리스트로)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: .setTimerDidFinishAll, object: nil) // 2) 루틴리스트도 pop
                }
            }
        }
        // ✅ 잠금화면 Live Activity의 "세트 완료" 버튼 처리
        .onReceive(NotificationCenter.default.publisher(for: .lockCommand)) { note in
            guard let cmd = note.object as? LockCommand else { return }
            if cmd == .setComplete {
                viewModel.markSetCompleted()
            }
        }
        // ✅ 화면 이탈 시 안전하게 종료(미완료 종료 시)
        .onDisappear {
            if #available(iOS 16.1, *), didStartLiveActivity, !viewModel.didFinishAll {
                LiveActivityManager.end()
                didStartLiveActivity = false
            }
        }
    }
}

// Exercise → SetTimerWorkout 브릿지 이니셜라이저
extension SetTimerView {
    init(exercises: [Exercise], routineTitle: String? = nil) {
        self.initialWorkouts = exercises.map {
            SetTimerWorkout(name: $0.name, totalSets: $0.sets, restTime: $0.restTime)
        }
        self.routineTitle = routineTitle
    }
}
