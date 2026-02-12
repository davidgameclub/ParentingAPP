//
//  ParentingAPPApp.swift
//  ParentingAPP
//
//  Created by Michael on 2026/2/12.
//

import SwiftUI
import CoreData

@main
struct ParentingAPPApp: App {
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
