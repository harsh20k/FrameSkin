//
//  FrameSkinApp.swift
//  FrameSkin
//
//  Created by harsh  on 27/05/24.
//

import SwiftUI

@main
struct FrameSkinApp: App {
    var body: some Scene {
        WindowGroup {
            let _ = UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
            let _ = print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path)
            ContentView()
        }
    }
}

