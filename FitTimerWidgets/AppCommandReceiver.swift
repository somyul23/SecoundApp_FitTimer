import Foundation

final class AppCommandReceiver {
    static let shared = AppCommandReceiver()
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onLocalCommand(_:)),
                                               name: .lockCommand, object: nil)
    }

    @objc private func onLocalCommand(_ note: Notification) {
        guard let cmd = note.object as? LockCommand else { return }
        handle(cmd: cmd)
    }

    // AppCommandReceiver.swift
    func handle(cmd: LockCommand) {
        if #available(iOS 16.1, *) {
            switch cmd {
            case .setComplete:
                Task { @MainActor in LiveActivityManager.advanceSetTimerImmediate() }
            case .tabataPause:
                Task { @MainActor in LiveActivityManager.pauseTabataImmediate() }
            case .tabataReset:
                Task { @MainActor in LiveActivityManager.end() }
            }
        }
        NotificationCenter.default.post(name: .lockCommand, object: cmd)
    }

}
