import WidgetKit
import SwiftUI
import ActivityKit

@main
struct FitTimerWidgets: WidgetBundle {
    var body: some Widget {
        // Live Activity (잠금화면/아일랜드)
        if #available(iOS 16.1, *) { WorkoutLiveActivity() }
        // ✅ 정식 홈 화면 위젯 2종
        WeeklyChartWidget()   // Medium: 주간 라인차트 (지난주=회색, 이번주=초록)
        RoutineListWidget()   // Large : 루틴 리스트 → 탭 시 딥링크 실행
    }
}

@available(iOS 16.1, *)
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            let s = context.state

            VStack(spacing: 8) {
                Text(context.attributes.title).font(.headline)
                if let sub = context.attributes.subtitle { Text(sub).font(.subheadline) }

                // 텍스트: 운동중 / 휴식중 / 일시정지
                Text(s.phase == .work ? "운동중" : (s.phase == .rest ? "휴식중" : "일시정지"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let range = s.remaining {
                    Text(timerInterval: range)
                        .monospacedDigit()
                        .font(.system(size: 28, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .center)   // 중앙 정렬
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 12) {
                    if context.attributes.mode == .setTimer {
                        Link(destination: URL(string: "fittimer://action/setComplete")!) {
                            Label("세트 완료", systemImage: "checkmark.circle.fill")
                        }
                    } else {
                        Link(destination: URL(string: "fittimer://action/tabataPause")!) {
                            Label("일시정지", systemImage: "pause.circle.fill")
                        }
                        Link(destination: URL(string: "fittimer://action/tabataReset")!) {
                            Label("초기화", systemImage: "arrow.counterclockwise.circle.fill")
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .activityBackgroundTint(.white)                   // ✅ 흰색 배경
            .activitySystemActionForegroundColor(.black)      // ✅ 버튼/텍스트는 검정색
            .environment(\.colorScheme, .light)               // ✅ 항상 라이트 모드 유지

            .widgetURL(URL(string: "fittimer://open")!)

        } dynamicIsland: { context in
            let s = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(s.phase == .work ? "운동중" : (s.phase == .rest ? "휴식중" : "정지"))
                        .bold()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let r = s.remaining {
                        Text(timerInterval: r)
                            .monospacedDigit()
                            .font(.title3.bold())
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        if context.attributes.mode == .setTimer {
                            Link(destination: URL(string: "fittimer://action/setComplete")!) {
                                Label("세트 완료", systemImage: "checkmark.circle.fill")
                            }
                        } else {
                            Link(destination: URL(string: "fittimer://action/tabataPause")!) {
                                Label("일시정지", systemImage: "pause.circle.fill")
                            }
                            Link(destination: URL(string: "fittimer://action/tabataReset")!) {
                                Label("초기화", systemImage: "arrow.counterclockwise.circle.fill")
                            }
                        }
                    }
                }
            } compactLeading: {
                Text(s.phase == .work ? "운동중" : (s.phase == .rest ? "휴식중" : "정지"))
            } compactTrailing: {
                if let r = s.remaining { Text(timerInterval: r).monospacedDigit() }
            } minimal: {
                if let r = s.remaining { Text(timerInterval: r).monospacedDigit() }
            }
        }
    }
}
