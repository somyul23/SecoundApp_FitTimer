import Foundation
import Combine

// MARK: - 개별 세트 이력
struct SetEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let routineName: String
    let exerciseName: String
    let setIndex: Int            // 1-based
    let plannedRest: Int         // 설정(초)
    var actualRest: Int?         // 실제(초) — 휴식 끝나면 업데이트
}

// MARK: - 세션(운동 전체) 이력
struct WorkoutRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let routineName: String
    let totalSets: Int
    let completedSets: Int
    var notes: String
}

// MARK: - 스토어 (Singleton)
final class WorkoutRecordStore: ObservableObject {
    static let shared = WorkoutRecordStore()

    @Published private(set) var records: [WorkoutRecord] = []
    @Published private(set) var setEvents: [SetEvent] = []

    private let recordsKey = "workout_records_v1"
    private let eventsKey  = "workout_set_events_v1"
    private let queue = DispatchQueue(label: "WorkoutRecordStore")

    private init() {
        loadAll()
    }

    // MARK: - Public API

    /// 운동 기록 추가
    func add(_ record: WorkoutRecord) {
        queue.async {
            var copy = self.records
            copy.insert(record, at: 0)
            self.persistRecords(copy)
        }
    }

    /// 세트 이벤트 추가
    func addSetEvent(_ event: SetEvent) {
        queue.async {
            var copy = self.setEvents
            copy.insert(event, at: 0)
            self.persistEvents(copy)
        }
    }

    /// 세트 실제 휴식 시간 업데이트
    func updateSetEventActualRest(id: UUID, actualRest: Int) {
        queue.async {
            var copy = self.setEvents
            if let idx = copy.firstIndex(where: { $0.id == id }) {
                copy[idx].actualRest = actualRest
                self.persistEvents(copy)
            }
        }
    }

    // ✅ 오늘 날짜의 특정 운동 기록만 삭제
    func deleteTodayRecords(for routineName: String, exerciseName: String) {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: Date())
        let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay)!

        queue.async {
            var copy = self.setEvents
            let before = copy.count

            copy.removeAll {
                $0.routineName == routineName &&
                $0.exerciseName == exerciseName &&
                $0.date >= startOfDay && $0.date < endOfDay
            }

            let deleted = before - copy.count
            if deleted > 0 {
                print("🗑️ Deleted \(deleted) setEvents for '\(exerciseName)' (\(routineName)) today.")
                self.persistEvents(copy)
            }
        }
    }

    // MARK: - Persistence

    private func loadAll() {
        if let d = UserDefaults.standard.data(forKey: recordsKey),
           let items = try? JSONDecoder().decode([WorkoutRecord].self, from: d) {
            self.records = items
        }

        if let d = UserDefaults.standard.data(forKey: eventsKey),
           let items = try? JSONDecoder().decode([SetEvent].self, from: d) {
            self.setEvents = items
        }
    }

    private func persistRecords(_ items: [WorkoutRecord]) {
        if let data = try? JSONEncoder().encode(items) {
            DispatchQueue.main.async {
                self.records = items
                UserDefaults.standard.set(data, forKey: self.recordsKey)
            }
        }
    }

    private func persistEvents(_ items: [SetEvent]) {
        if let data = try? JSONEncoder().encode(items) {
            DispatchQueue.main.async {
                self.setEvents = items
                UserDefaults.standard.set(data, forKey: self.eventsKey)
            }
        }
    }
}
