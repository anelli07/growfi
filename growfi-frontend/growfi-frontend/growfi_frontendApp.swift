//
//  growfi_frontendApp.swift
//  growfi-frontend
//
//  Created by Anel Anuash on 02.07.2025.
//

import SwiftUI

@main
struct growfi_frontendApp: App {
    @StateObject private var goalsViewModel = GoalsViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(goalsViewModel)
        }
    }
}
