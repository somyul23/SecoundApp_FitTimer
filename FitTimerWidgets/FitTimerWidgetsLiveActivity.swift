//
//  FitTimerWidgetsLiveActivity.swift
//  FitTimerWidgets
//
//  Created by 김영우 on 9/8/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FitTimerWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FitTimerWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FitTimerWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.white)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension FitTimerWidgetsAttributes {
    fileprivate static var preview: FitTimerWidgetsAttributes {
        FitTimerWidgetsAttributes(name: "World")
    }
}

extension FitTimerWidgetsAttributes.ContentState {
    fileprivate static var smiley: FitTimerWidgetsAttributes.ContentState {
        FitTimerWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FitTimerWidgetsAttributes.ContentState {
         FitTimerWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FitTimerWidgetsAttributes.preview) {
   FitTimerWidgetsLiveActivity()
} contentStates: {
    FitTimerWidgetsAttributes.ContentState.smiley
    FitTimerWidgetsAttributes.ContentState.starEyes
}
