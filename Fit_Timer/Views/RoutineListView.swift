import SwiftUI
import Combine

// MARK: - Persistence
private let routinesStorageKey = "routines_v2_json"

private struct PersistedExercise: Codable, Hashable {
    var id: UUID
    var name: String
    var sets: Int
    var restTime: Int
}
private struct PersistedRoutine: Codable, Hashable {
    var id: UUID
    var name: String
    var exercises: [PersistedExercise]
}

// MARK: - 단일 Route (프로그램적 내비게이션만 사용)
private enum Route: Identifiable, Hashable {
    case detail(UUID)
    case run(UUID)

    var id: String {
        switch self {
        case .detail(let id): return "detail-\(id.uuidString)"
        case .run(let id):    return "run-\(id.uuidString)"
        }
    }
}

struct RoutineListView: View {
    // Storage
    @AppStorage(routinesStorageKey) private var routinesBlob: Data = Data()

    // State
    @State private var routines: [Routine] = []
    @State private var expandedIndex: Int? = nil
    @State private var isEditing = false
    @State private var editMode: EditMode = .inactive
    @State private var showingAddRoutine = false

    // Alerts
    @State private var selectedDeleteIndex: Int? = nil
    @State private var showDeleteAlert = false
    @State private var showEmptyAlert = false

    // ✅ 단일 네비 상태
    @State private var route: Route?

    // ✅ 딥링크/완료 pop 대응
    @Environment(\.dismiss) private var dismiss
    
    var startRoutineIDOnAppear: UUID? = nil
    
    var body: some View {
        // ⚠️ 이 뷰 내부엔 NavigationStack 두지 마세요 (중첩 스택 금지)
        List {
            if isEditing {
                Section {
                    AddRoutineRow { showingAddRoutine = true }
                }
            }

            ForEach(routines.indices, id: \.self) { index in
                RoutineRowView(
                    routine: routines[index],
                    name: $routines[index].name,
                    isExpanded: expandedIndex == index,
                    isEditing: isEditing,
                    onTapRow: { handleTapRow(index) },
                    onDetailTap: { goDetail(index) },           // ✅ 버튼 → route = .detail
                    onRunTap: { runTimer(index) }               // ✅ 버튼 → route = .run (또는 alert)
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        presentDelete(index)
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
            }
            .onMove { from, to in
                guard isEditing else { return }
                routines.move(fromOffsets: from, toOffset: to)
                saveRoutines()
            }
        }
        .navigationTitle("루틴 선택")
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "확인" : "편집") {
                    withAnimation {
                        isEditing.toggle()
                        editMode = isEditing ? .active : .inactive
                        expandedIndex = nil
                    }
                }
            }
        }

        // Alerts
        .alert(isPresented: $showDeleteAlert) {
            let name = selectedDeleteIndex.flatMap { routines[$0].name } ?? ""
            return Alert(
                title: Text("\"\(name)\"을 삭제하시겠습니까?"),
                primaryButton: .destructive(Text("삭제")) {
                    if let idx = selectedDeleteIndex, routines.indices.contains(idx) {
                        routines.remove(at: idx)
                        saveRoutines()
                    }
                    selectedDeleteIndex = nil
                },
                secondaryButton: .cancel { selectedDeleteIndex = nil }
            )
        }
        .alert("해당 루틴에는 아직 아무런 운동이 없습니다.", isPresented: $showEmptyAlert) {
            Button("확인", role: .cancel) { }
        }

        // Add sheet
        .sheet(isPresented: $showingAddRoutine) {
            AddRoutineSheet(isPresented: $showingAddRoutine) { name in
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                withAnimation {
                    routines.insert(Routine(name: trimmed, exercises: []), at: 0)
                }
                saveRoutines()
            }
        }

        // ✅ 이 뷰 “한 곳에서만” 목적지 등록
        .navigationDestination(item: $route) { route in
            switch route {
            case .detail(let id):
                if let idx = routines.firstIndex(where: { $0.id == id }) {
                    RoutineDetailView(routine: $routines[idx])
                } else {
                    Text("루틴을 찾을 수 없습니다.")
                }
            case .run(let id):
                if let idx = routines.firstIndex(where: { $0.id == id }) {
                    let ex = routines[idx].exercises
                    SetTimerView(exercises: ex, routineTitle: routines[idx].name)
                } else {
                    Text("루틴을 찾을 수 없습니다.")
                }
            }
        }

        // Persistence hooks
        .onAppear { loadRoutinesIfNeeded()
            if let targetID = startRoutineIDOnAppear {
                    DispatchQueue.main.async { // 데이터 로드 후 한 프레임 뒤에 실행
                        if let routine = routines.first(where: { $0.id == targetID }) {
                            if routine.exercises.isEmpty {
                                showEmptyAlert = true
                            } else {
                                route = .run(targetID)
                            }
                        }
                    }
                }
            }
        .onChange(of: routines) { saveRoutines() }        // iOS 17 스타일
        .onChange(of: routinesBlob) {
            // 자기-쓰기 guard
            let payload: [PersistedRoutine] = routines.map { r in
                PersistedRoutine(
                    id: r.id, name: r.name,
                    exercises: r.exercises.map { e in
                        PersistedExercise(id: e.id, name: e.name, sets: e.sets, restTime: e.restTime)
                    }
                )
            }
            let currentData = (try? JSONEncoder().encode(payload)) ?? Data()
            guard currentData != routinesBlob else { return }
            loadRoutinesFromBlob()

            // ✅ 위젯 Large(루틴 목록) 즉시 갱신
            WidgetDataSync.publishRoutinesFromBlob(routinesBlob)
        }

        // ✅ 딥링크: fittimer://startRoutine?id=UUID → 바로 실행 네비게이션
        .onReceive(NotificationCenter.default.publisher(for: .startRoutineDeepLink)) { note in
            guard let idString = note.object as? String,
                  let uuid = UUID(uuidString: idString),
                  let routine = routines.first(where: { $0.id == uuid }) else { return }

            if routine.exercises.isEmpty {
                showEmptyAlert = true
            } else {
                route = .run(uuid)
            }
        }

        // ✅ 세트 전부 완료 → 루틴 리스트도 pop (홈으로)
        .onReceive(NotificationCenter.default.publisher(for: .setTimerDidFinishAll)) { _ in
            dismiss()
        }
    }

    // MARK: - Actions
    private func handleTapRow(_ index: Int) {
        guard !isEditing else { return }
        withAnimation(.easeInOut) {
            expandedIndex = (expandedIndex == index) ? nil : index
        }
    }
    private func presentDelete(_ index: Int) {
        selectedDeleteIndex = index
        showDeleteAlert = true
    }
    private func goDetail(_ index: Int) {
        guard routines.indices.contains(index) else { return }
        route = .detail(routines[index].id)     // ✅ 상세는 상세로만
    }
    private func runTimer(_ index: Int) {
        guard routines.indices.contains(index) else { return }
        let ex = routines[index].exercises
        if ex.isEmpty {
            showEmptyAlert = true                // ✅ 빈 루틴이면 실행 안 함
        } else {
            route = .run(routines[index].id)     // ✅ 실행은 실행으로만
        }
    }

    // MARK: - Persistence
    private func loadRoutinesIfNeeded() {
        if routines.isEmpty {
            loadRoutinesFromBlob()
            if routines.isEmpty {
                routines = [
                    Routine(name: "상체 운동", exercises: [
                        Exercise(name: "푸쉬업", sets: 3, restTime: 30)
                    ]),
                    Routine(name: "하체 운동", exercises: [])
                ]
                saveRoutines()
            }
        }
    }
    private func loadRoutinesFromBlob() {
        guard !routinesBlob.isEmpty else { return }
        do {
            let decoded = try JSONDecoder().decode([PersistedRoutine].self, from: routinesBlob)
            self.routines = decoded.map { pr in
                Routine(
                    id: pr.id,
                    name: pr.name,
                    exercises: pr.exercises.map { pe in
                        Exercise(id: pe.id, name: pe.name, sets: pe.sets, restTime: pe.restTime)
                    }
                )
            }
        } catch { /* log if needed */ }
    }
    private func saveRoutines() {
        let payload: [PersistedRoutine] = routines.map { r in
            PersistedRoutine(
                id: r.id,
                name: r.name,
                exercises: r.exercises.map { e in
                    PersistedExercise(id: e.id, name: e.name, sets: e.sets, restTime: e.restTime)
                }
            )
        }
        do {
            let data = try JSONEncoder().encode(payload)
            if data != routinesBlob { routinesBlob = data } // 자기-쓰기 방지
            // ✅ 저장 직후에도 위젯에 밀어두면 반영이 더 빠름
            WidgetDataSync.publishRoutinesFromBlob(routinesBlob)
        } catch { /* log if needed */ }
    }
}

// MARK: - Row
private struct RoutineRowView: View {
    let routine: Routine
    @Binding var name: String
    let isExpanded: Bool
    let isEditing: Bool

    let onTapRow: () -> Void
    let onDetailTap: () -> Void
    let onRunTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                TextField("루틴 이름", text: $name)
                    .font(.headline)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .submitLabel(.done)
            } else {
                HStack {
                    Text(name).font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .contentShape(Rectangle())
                .onTapGesture { onTapRow() }
            }

            if isExpanded && !isEditing {
                ExpandedButtons(onDetailTap: onDetailTap, onRunTap: onRunTap)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
        .buttonStyle(.plain)      // 버튼 탭 전파 방지
        .contentShape(Rectangle())
    }
}

private struct ExpandedButtons: View {
    let onDetailTap: () -> Void
    let onRunTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onDetailTap) {
                Text("상세")
                    .font(.subheadline)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
            }
            Button(action: onRunTap) {
                Text("실행")
                    .font(.subheadline)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

// '+ 루틴 추가' 셀 & AddRoutineSheet
private struct AddRoutineRow: View {
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("새 루틴 추가")
            }
        }
    }
}

private struct AddRoutineSheet: View {
    @Binding var isPresented: Bool
    var onAdd: (String) -> Void
    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("새 루틴 이름").font(.headline)
                TextField("루틴 이름을 입력하세요", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                HStack(spacing: 12) {
                    Button("취소") { isPresented = false }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.gray.opacity(0.2)).cornerRadius(10)
                    Button("추가") {
                        onAdd(name); isPresented = false
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.blue).foregroundColor(.white).cornerRadius(10)
                }
                .padding(.horizontal)
                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("루틴 추가")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
