//
//  BalanceWidgetBundle.swift
//  BalanceWidget
//
//  Created by Mani on 31.01.26.
//

import WidgetKit
import SwiftUI

@main
struct BalanceWidgetBundle: WidgetBundle {
    var body: some Widget {
        BalanceWidget()
        BalanceWidgetControl()
        BalanceWidgetLiveActivity()
    }
}
