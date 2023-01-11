//
//  BudgetAppApp.swift
//  BudgetApp
//
//  Created by paige shin on 2023/01/11.
//

import SwiftUI

@main
struct BudgetAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
        }
    }
}
