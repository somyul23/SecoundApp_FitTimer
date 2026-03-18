import SwiftUI

struct MenuView: View {
    var body: some View {
        List {
            NavigationLink(destination: WorkoutHistoryView()) {
                Label("운동 기록 보기", systemImage: "doc.text.magnifyingglass")
            }

            NavigationLink(destination: SettingsView()) {
                Label("설정", systemImage: "gearshape")
            }
        }
        .navigationTitle("메뉴")
    }
}
