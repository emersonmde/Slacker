//
//  SlackerApp.swift
//  Slacker
//
//  Created by Matthew Emerson on 6/7/22.
//

import SwiftUI

@main
struct SlackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
