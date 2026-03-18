//
//  FitTimerWidgetsBundle.swift
//  FitTimerWidgets
//
//  Created by 김영우 on 9/8/25.
//

import WidgetKit
import SwiftUI

@main
struct FitTimerWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FitTimerWidgets()
        FitTimerWidgetsControl()
        FitTimerWidgetsLiveActivity()
    }
}
