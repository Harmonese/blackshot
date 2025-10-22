//
//  BlackshotApp.swift
//  Blackshot
//
//  Created by xuzihao on 2025/10/22.
//

import SwiftUI
import CoreData

@main
struct BlackshotApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
