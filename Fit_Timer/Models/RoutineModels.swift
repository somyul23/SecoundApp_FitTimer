import Foundation

struct Routine: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var exercises: [Exercise]

    // ✅ id 주입 가능한 init (복원 시 필요)
    init(id: UUID = UUID(), name: String, exercises: [Exercise]) {
        self.id = id
        self.name = name
        self.exercises = exercises
    }
}

struct Exercise: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var sets: Int
    var restTime: Int

    // ✅ id 주입 가능한 init
    init(id: UUID = UUID(), name: String, sets: Int, restTime: Int) {
        self.id = id
        self.name = name
        self.sets = sets
        self.restTime = restTime
    }
}
