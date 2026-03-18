import SwiftUI

private let routinesStorageKey = "routines_v2_json"

// MARK: - Codable Models
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

// MARK: - Routine Detail
struct RoutineDetailView: View {
    @Binding var routine: Routine

    // 로컬 상태
    @State private var localName: String = ""
    @State private var localExercises: [Exercise] = []

    // 편집 제어
    @State private var isEditing = false
    @State private var editMode: EditMode = .inactive
    @State private var showingAddExercise = false

    // 실행 관련
    @State private var selectedExerciseID: UUID?
    @State private var navigateToSetTimer = false

    // 저장소
    @AppStorage(routinesStorageKey) private var routinesBlob: Data = Data()

    // MARK: - Destination View (NavigationLink 성능 개선용)
    @ViewBuilder
    private var destinationView: some View {
        if let id = selectedExerciseID,
           let ex = localExercises.first(where: { $0.id == id }) {
            SetTimerView(exercises: [ex], routineTitle: localName)
        } else {
            EmptyView()
        }
    }

    var body: some View {
        List {
            nameSection
            exerciseSection
        }
        .animation(.default, value: localExercises)
        .navigationTitle("루틴 상세")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbar { editToolbar }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseSheet { newExercise in
                withAnimation { localExercises.append(newExercise) }
            }
        }
        .background(
            NavigationLink(destination: destinationView, isActive: $navigateToSetTimer) {
                EmptyView()
            }
            .hidden()
        )
        .onAppear(perform: loadFromParent)
        .onDisappear(perform: syncBackToParentAndPersist)
        .onChange(of: localName) { _ in syncBackToParentAndPersist() }
        .onChange(of: localExercises) { _ in syncBackToParentAndPersist() }
        .onChange(of: routine.name) { if routine.name != localName { localName = routine.name } }
        .onChange(of: routine.exercises) { syncIfRoutineChanged() }
    }

    // MARK: - Sections
    private var nameSection: some View {
        Section {
            if isEditing {
                TextField("루틴 이름", text: $localName)
                    .font(.title2.bold())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .submitLabel(.done)
            } else {
                Text(localName)
                    .font(.title2.bold())
            }
        }
    }

    private var exerciseSection: some View {
        Section(header: Text("운동 \(localExercises.count)개")) {
            ForEach($localExercises) { $exercise in
                VStack(spacing: 0) {
                    ExerciseRow(exercise: $exercise, isEditing: isEditing)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                selectedExerciseID = (selectedExerciseID == exercise.id) ? nil : exercise.id
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if let idx = localExercises.firstIndex(where: { $0.id == exercise.id }) {
                                    withAnimation { localExercises.remove(at: idx) }
                                }
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }

                    // 실행 버튼
                    if selectedExerciseID == exercise.id {
                        Button {
                            navigateToSetTimer = true
                        } label: {
                            Label("이 운동 실행", systemImage: "play.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.9))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .onDelete { offsets in
                withAnimation { localExercises.remove(atOffsets: offsets) }
            }
            .onMove { from, to in
                withAnimation { localExercises.move(fromOffsets: from, toOffset: to) }
            }

            if isEditing {
                Button {
                    showingAddExercise = true
                } label: {
                    Label("운동 추가", systemImage: "plus.circle.fill")
                }
                .accessibilityIdentifier("addExerciseInlineButton")
            }
        }
    }

    // MARK: - Toolbar
    private var editToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(isEditing ? "완료" : "편집") {
                withAnimation {
                    isEditing.toggle()
                    editMode = isEditing ? .active : .inactive
                }
            }
            .accessibilityIdentifier("toggleEditButton")
        }
    }

    // MARK: - Data Handling
    private func loadFromParent() {
        localName = routine.name
        localExercises = routine.exercises
    }

    private func syncIfRoutineChanged() {
        let lhs = Set(localExercises.map(\.id))
        let rhs = Set(routine.exercises.map(\.id))
        if lhs != rhs || localExercises.count != routine.exercises.count {
            localExercises = routine.exercises
        }
    }

    private func syncBackToParentAndPersist() {
        if routine.name != localName { routine.name = localName }
        if routine.exercises != localExercises { routine.exercises = localExercises }
        persistRoutineToStorage()
    }

    private func persistRoutineToStorage() {
        do {
            var list: [PersistedRoutine] = []
            if !routinesBlob.isEmpty,
               let decoded = try? JSONDecoder().decode([PersistedRoutine].self, from: routinesBlob) {
                list = decoded
            }

            let current = PersistedRoutine(
                id: routine.id,
                name: routine.name,
                exercises: routine.exercises.map {
                    PersistedExercise(id: $0.id, name: $0.name, sets: $0.sets, restTime: $0.restTime)
                }
            )

            if let idx = list.firstIndex(where: { $0.id == current.id }) {
                list[idx] = current
            } else {
                list.append(current)
            }

            let data = try JSONEncoder().encode(list)
            if data != routinesBlob { routinesBlob = data }
        } catch {
            #if DEBUG
            print("persistRoutineToStorage error:", error.localizedDescription)
            #endif
        }
    }
}

// MARK: - ExerciseRow
private struct ExerciseRow: View {
    @Binding var exercise: Exercise
    let isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                TextField("운동 이름", text: $exercise.name)
                    .font(.headline)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .submitLabel(.done)

                Stepper(value: $exercise.sets, in: 1...100) {
                    HStack {
                        Text("세트 수")
                        Spacer()
                        Text("\(exercise.sets)세트")
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("휴식 시간(초)")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    Picker("", selection: $exercise.restTime) {
                        ForEach(1...100, id: \.self) { sec in
                            Text("\(sec)초").tag(sec)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
            } else {
                HStack {
                    Text(exercise.name)
                        .font(.headline)
                    Spacer()
                    HStack(spacing: 12) {
                        Label("\(exercise.sets)", systemImage: "rectangle.grid.1x2")
                        Label("\(exercise.restTime)s", systemImage: "timer")
                    }
                    .foregroundColor(.secondary)
                    .labelStyle(.iconOnly)
                }
                Text("세트 \(exercise.sets) · 휴식 \(exercise.restTime)초")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - AddExerciseSheet
private struct AddExerciseSheet: View {
    var onAdd: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var sets = 3
    @State private var restSeconds = 30

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("운동 정보")) {
                    TextField("운동 이름", text: $name)
                        .textInputAutocapitalization(.words)

                    Stepper(value: $sets, in: 1...100) {
                        HStack {
                            Text("세트 수")
                            Spacer()
                            Text("\(sets)세트")
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("휴식 시간(초)")
                            .font(.callout)
                            .foregroundColor(.secondary)

                        Picker("", selection: $restSeconds) {
                            ForEach(1...100, id: \.self) { sec in
                                Text("\(sec)초").tag(sec)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.wheel)
                        .frame(height: 140)
                    }
                }
            }
            .navigationTitle("운동 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onAdd(Exercise(name: trimmed, sets: sets, restTime: restSeconds))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
