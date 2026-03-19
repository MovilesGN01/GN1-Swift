//
//  GN1_SwiftApp.swift
//  GN1-Swift
//
//  Created by Camilo Sanchez Novoa on 2/03/26.
//

import SwiftUI

@main
struct GN1_SwiftApp: App {
    @State private var isLoggedIn = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                TabViewmain()
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}
