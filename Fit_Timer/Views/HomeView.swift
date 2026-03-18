import SwiftUI
import ActivityKit

struct HomeView: View {
    // 위젯 동기화 및 루틴 디코드용
    @AppStorage("routines_v2_json") private var routinesBlob: Data = Data()

    // 딥링크 → SetTimerView “직행” 상태
    @State private var openSetTimerDirect = false
    @State private var preparedWorkouts: [SetTimerWorkout] = []
    @State private var preparedRoutineTitle: String = ""
    @State private var showEmptyRoutineAlert = false

    var body: some View {
        NavigationStack {
            VStack {
                // 상단 바
                HStack {
                    NavigationLink(destination: WorkoutHistoryView()) { //바로 길
                        Image(systemName: "line.horizontal.3")
                            .resizable()
                            .frame(width: 24, height: 16)
                            .padding()
                    }
                    Spacer()
                    Text("Fit Timer")
                        .font(.title)
                        .bold()
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }

                Spacer()

                NavigationLink(destination: TabataTimerView()) {
                    Text("🔥 타바타 타이머")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer().frame(height: 24)

                NavigationLink(destination: RoutineListView()) {
                    Text("🏋️ 세트 타이머")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer()
            }
            // ✅ 홈 진입 시 위젯에 실데이터 밀어주기
            .onAppear {
                WidgetDataSync.publishWeeklyFromSetEvents(WorkoutRecordStore.shared.setEvents)
                WidgetDataSync.publishRoutinesFromBlob(routinesBlob)
            }
            // ✅ 위젯 딥링크 수신 → SetTimerView로 직행
            .onReceive(NotificationCenter.default.publisher(for: .startRoutineDeepLink)) { note in
                guard let idString = note.object as? String,
                      let uuid = UUID(uuidString: idString) else { return }
                prepareAndOpenSetTimer(uuid: uuid)
            }
            // 숨은 네비 링크: 준비된 워크아웃으로 푸시
            .background(
                NavigationLink(
                    isActive: $openSetTimerDirect,
                    destination: {
                        SetTimerView(initialWorkouts: preparedWorkouts,
                                     routineTitle: preparedRoutineTitle)
                    },
                    label: { EmptyView() }
                )
                .hidden()
            )
            .alert("해당 루틴에 운동이 없습니다.", isPresented: $showEmptyRoutineAlert) {
                Button("확인", role: .cancel) {}
            }
        }
    }

    // MARK: - 딥링크 처리: 루틴 ID → [SetTimerWorkout] 준비 후 바로 푸시
    private func prepareAndOpenSetTimer(uuid: UUID) {
        // AppStorage JSON 로컬 디코딩용 타입
        struct PExercise: Codable { let id: UUID; let name: String; let sets: Int; let restTime: Int }
        struct PRoutine:  Codable { let id: UUID; let name: String; let exercises: [PExercise] }

        guard let list = try? JSONDecoder().decode([PRoutine].self, from: routinesBlob),
              let target = list.first(where: { $0.id == uuid }) else {
            return
        }
        guard !target.exercises.isEmpty else {
            showEmptyRoutineAlert = true
            return
        }

        // ✅ 바로 SetTimerWorkout으로 변환(초기 렌더 타이밍 이슈 방지)
        let workouts: [SetTimerWorkout] = target.exercises.map {
            SetTimerWorkout(name: $0.name, totalSets: $0.sets, restTime: $0.restTime)
        }

        // 네비 전에 상태 세팅 완료
        preparedRoutineTitle = target.name
        preparedWorkouts = workouts

        // 다음 프레임에 푸시(안전)
        DispatchQueue.main.async {
            openSetTimerDirect = true
        }
    }
}
