import SwiftUI

extension Notification.Name {
    /// 루틴 바로 실행 딥링크 (payload: id String)
    static let startRoutineDeepLink = Notification.Name("startRoutineDeepLink")
}

@main
struct Fit_TimerApp: App {
    init() {
        _ = AppCommandReceiver.shared
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .onOpenURL { url in
                    guard url.scheme == "fittimer" else { return }

                    if url.host == "action" {
                        let cmd: LockCommand? = {
                            switch url.lastPathComponent {
                            case "setComplete": return .setComplete
                            case "tabataPause": return .tabataPause
                            case "tabataReset": return .tabataReset
                            default: return nil
                            }
                        }()
                        if let cmd { AppCommandReceiver.shared.handle(cmd: cmd) }

                    } else if url.host == "startRoutine" {
                        // fittimer://startRoutine?id=<UUID>
                        if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
                           let id = comps.queryItems?.first(where: { $0.name == "id" })?.value {
                            NotificationCenter.default.post(name: .startRoutineDeepLink, object: id)
                        }
                    }
                }
        }
    }
}
