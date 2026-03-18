import SwiftUI
import ActivityKit

struct TabataTimerView: View {
    @StateObject private var viewModel = TabataTimerViewModel()
    
    @State private var selectedWorkMinutes = 0
    @State private var selectedWorkSeconds = 20
    @State private var selectedRestMinutes = 0
    @State private var selectedRestSeconds = 10
    
    @State private var showPickers = true
    @State private var isRunning = false

    // 🔔 Live Activity 자동 관리
    @State private var didStartLiveActivity = false

    // Tabata 전역 Phase → LiveActivity Phase 변환
    private func attrPhase(_ p: Phase) -> WorkoutActivityAttributes.ContentState.Phase {
        switch p {
        case .work:   return WorkoutActivityAttributes.ContentState.Phase.work
        case .rest:   return WorkoutActivityAttributes.ContentState.Phase.rest
        case .stopped:return WorkoutActivityAttributes.ContentState.Phase.stopped
        }
    }

    // 🔁 Picker UI
    func timePicker(minutes: Binding<Int>, seconds: Binding<Int>) -> some View {
        HStack {
            Picker("분", selection: minutes) {
                ForEach(0..<6) { Text("\($0)분") }
            }
            .frame(width: 100).clipped().pickerStyle(.wheel)

            Picker("초", selection: seconds) {
                ForEach(0..<60) { Text("\($0)초") }
            }
            .frame(width: 100).clipped().pickerStyle(.wheel)
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(viewModel.state.currentPhase == .work || viewModel.state.currentPhase == .rest
                 ? "라운드 \(viewModel.state.currentRound)/\(viewModel.state.totalRounds)"
                 : "타바타 타이머")
                .font(.largeTitle).bold()
            
            if viewModel.state.currentPhase == .work {
                Text("🏋️‍♂️ 운동 중").font(.title2).foregroundColor(.red)
            } else if viewModel.state.currentPhase == .rest {
                Text("🛌 휴식 중").font(.title2).foregroundColor(.blue)
            }

            Group {
                if showPickers {
                    Stepper(value: $viewModel.totalRounds, in: 1...20) {
                        Text("라운드 수: \(viewModel.totalRounds)")
                    }
                } else {
                    Text("\(viewModel.state.timeRemaining)초")
                }
            }
            .font(.title2)
            .padding()

            if showPickers {
                VStack {
                    Text("운동 시간 설정").font(.headline)
                    timePicker(minutes: $selectedWorkMinutes, seconds: $selectedWorkSeconds)
                    
                    Text("휴식 시간 설정").font(.headline)
                    timePicker(minutes: $selectedRestMinutes, seconds: $selectedRestSeconds)
                }
            }

            HStack(spacing: 30) {
                Button(isRunning ? "일시정지" : "시작") {
                    if !isRunning {
                        if viewModel.state.currentPhase == .stopped {
                            let workTotal = selectedWorkMinutes * 60 + selectedWorkSeconds
                            let restTotal = selectedRestMinutes * 60 + selectedRestSeconds
                            viewModel.setDurations(work: workTotal, rest: restTotal)
                        }
                        viewModel.start()
                        isRunning = true
                        showPickers = false

                        // 시작 직후 Live Activity 업데이트
                        if #available(iOS 16.1, *), didStartLiveActivity {
                            LiveActivityManager.updateTabata(
                                roundCurrent: viewModel.state.currentRound,
                                roundTotal: viewModel.state.totalRounds,
                                phase: WorkoutActivityAttributes.ContentState.Phase.work,
                                seconds: viewModel.state.timeRemaining
                            )
                        }
                    } else {
                        viewModel.pause()
                        isRunning = false
                        if #available(iOS 16.1, *) {
                            LiveActivityManager.pauseTabataImmediate()
                        }
                    }
                }
                .font(.title3)
                .padding()
                .background(isRunning ? Color.orange : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("초기화") {
                    viewModel.reset()
                    isRunning = false
                    showPickers = true
                    if #available(iOS 16.1, *), didStartLiveActivity {
                        LiveActivityManager.end()
                        didStartLiveActivity = false
                    }
                }
                .font(.title3)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        // 🔗 잠금화면 컨트롤 수신
        .onReceive(NotificationCenter.default.publisher(for: .lockCommand)) { note in
            guard let cmd = note.object as? LockCommand else { return }
            switch cmd {
            case .tabataPause:
                viewModel.pause(); isRunning = false
            case .tabataReset:
                viewModel.reset(); isRunning = false; showPickers = true
                if #available(iOS 16.1, *), didStartLiveActivity {
                    LiveActivityManager.end()
                    didStartLiveActivity = false
                }
            default: break
            }
        }
        // 🔥 화면 진입 시 Live Activity 자동 시작
        .onAppear {
            if #available(iOS 16.1, *), !didStartLiveActivity {
                LiveActivityManager.startTabata(
                    title: "타바타",
                    roundCurrent: viewModel.state.currentRound,
                    roundTotal: viewModel.state.totalRounds,
                    phase: attrPhase(viewModel.state.currentPhase),   // ← 전역 Phase 사용
                    seconds: viewModel.state.timeRemaining
                )
                didStartLiveActivity = true
            }
        }
        // ⏱️ work/rest 전환 시 갱신
        .onChange(of: viewModel.state.currentPhase) { newPhase in
            guard #available(iOS 16.1, *), didStartLiveActivity else { return }
            let phase = attrPhase(newPhase)   // ← 전역 Phase → LiveActivity Phase
            let secs: Int = (newPhase == .work) ? viewModel.state.workDuration
                              : (newPhase == .rest ? viewModel.state.restDuration : 0)
            LiveActivityManager.updateTabata(
                roundCurrent: viewModel.state.currentRound,
                roundTotal: viewModel.state.totalRounds,
                phase: phase,
                seconds: secs
            )
        }
        /*
        // 🚪 화면 이탈 시 종료(원치 않으면 제거)
        .onDisappear {
            if #available(iOS 16.1, *), didStartLiveActivity {
                LiveActivityManager.end()
                didStartLiveActivity = false
            }
        }
         */
    }
}
