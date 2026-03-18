import WidgetKit
import SwiftUI

// MARK: - Model
struct RoutineItem: Codable, Hashable, Identifiable {
    let id: String      // ⚠️ 앱에서 UUID.uuidString 으로 채워줘야 루틴 실행 딥링크가 동작함
    let name: String
    let sets: Int
}

struct RoutineEntry: TimelineEntry {
    let date: Date
    let items: [RoutineItem]
}

// MARK: - Provider
struct RoutineProvider: TimelineProvider {
    func placeholder(in context: Context) -> RoutineEntry {
        // 갤러리 미리보기용으로만 샘플 유지
        RoutineEntry(date: .now, items: sample())
    }

    func getSnapshot(in context: Context, completion: @escaping (RoutineEntry) -> Void) {
        completion(load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RoutineEntry>) -> Void) {
        completion(Timeline(entries: [load()], policy: .after(Date().addingTimeInterval(60 * 15))))
    }

    /// App Group에서 실제 데이터 로드. 없으면 "빈 배열" 반환(=샘플 금지)
    private func load() -> RoutineEntry {
        let ud = UserDefaults(suiteName: Shared.appGroupId) ?? .standard
        if let data = ud.data(forKey: "widget_routines"),
           let decoded = try? JSONDecoder().decode([RoutineItem].self, from: data) {
            return RoutineEntry(date: .now, items: decoded)
        }
        return RoutineEntry(date: .now, items: []) // ← 실제 데이터 없으면 빈 상태
    }

    /// placeholder 용 샘플(위젯 갤러리 미리보기에서만 사용)
    private func sample() -> [RoutineItem] {
        [
            RoutineItem(id: UUID().uuidString, name: "가슴/삼두", sets: 12),
            RoutineItem(id: UUID().uuidString, name: "등/이두", sets: 10),
            RoutineItem(id: UUID().uuidString, name: "하체", sets: 14)
        ]
    }
}

// MARK: - View
struct RoutineListWidgetView: View {
    let entry: RoutineEntry

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("루틴 실행").font(.headline)

            if entry.items.isEmpty {
                // ✅ 빈 상태 UI: 앱을 한 번 열어 동기화하도록 유도
                VStack(alignment: .leading, spacing: 6) {
                    Text("표시할 루틴이 없어요")
                        .font(.subheadline).bold()
                    Text("앱을 한 번 열면 위젯과 동기화돼요.")
                        .font(.caption).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
            } else {
                ForEach(entry.items.prefix(5)) { r in
                    if #available(iOSApplicationExtension 17.0, *) {
                        Link(destination: URL(string: "fittimer://startRoutine?id=\(r.id)")!) {
                            HStack {
                                Text(r.name).lineLimit(1)
                                Spacer()
                                Text("\(r.sets)세트").foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        // iOS 16: 항목은 표기만, 탭하면 전체 위젯 URL로 앱 열기
                        HStack {
                            Text(r.name).lineLimit(1)
                            Spacer()
                            Text("\(r.sets)세트").foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(12)
        // iOS 16 폴백: 헤더/빈화면 클릭 시 앱 열기
        .widgetURL(URL(string: "fittimer://open")!)
    }

    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content
                .containerBackground(for: .widget) { Color.clear } // iOS17 위젯 배경 API
        } else {
            content
        }
    }
}

// MARK: - Config
struct RoutineListWidget: Widget {
    let kind = "RoutineListWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RoutineProvider()) { entry in
            RoutineListWidgetView(entry: entry)
        }
        .configurationDisplayName("루틴 바로 실행")
        .description("위젯에서 바로 루틴을 선택해 실행")
        .supportedFamilies([.systemLarge])
    }
}
