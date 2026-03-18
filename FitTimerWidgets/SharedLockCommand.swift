import Foundation

// 잠금화면 버튼 → 앱으로 전달할 커맨드
enum LockCommand: String {
    case setComplete
    case tabataPause
    case tabataReset
}

// 노티 이름(앱 내부 브로드캐스트)
extension Notification.Name {
    static let lockCommand = Notification.Name("com.yourco.fittimer.lockCommand")
}

// AppGroup 공유 스토리지(선택적으로 사용)
enum Shared {
    static let appGroupId = "group.com.yourco.fittimer"
    static let defaults = UserDefaults(suiteName: appGroupId) ?? .standard
    static let commandKey = "lock_command_key"
    static let darwinName = "com.yourco.fittimer.lockcommand.darwin"
}
