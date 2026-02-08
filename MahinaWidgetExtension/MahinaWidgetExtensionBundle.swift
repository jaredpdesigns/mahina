//
//  MahinaWidgetExtensionBundle.swift
//  MahinaWidgetExtension
//
//  Created by Jared Pendergraft on 11/26/25.
//

import WidgetKit
import SwiftUI
import MahinaAssets

@main
struct MahinaWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        MahinaWidgetExtension()
        UpcomingPhasesWidget()
    }
}
