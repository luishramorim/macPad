//
//  AboutWindowManager.swift
//  macPad
//
//  Created by Luis Amorim on 20/02/25.
//

import Cocoa
import SwiftUI

/**
 Opens the custom About window.
 
 This function creates an NSWindow hosting the AboutView, configures its appearance, and makes it key and visible.
 */
func showAboutWindow() {
    // Create the hosting controller with AboutView.
    let hostingController = NSHostingController(rootView: AboutView())
    // Create a new window for the about content.
    let aboutWindow = NSWindow(contentViewController: hostingController)
    
    aboutWindow.title = "About macPad"
    aboutWindow.styleMask = [.titled, .closable, .miniaturizable]
    aboutWindow.isReleasedWhenClosed = false  // Keep the window in memory if needed.
    
    // Center and display the window.
    aboutWindow.center()
    aboutWindow.makeKeyAndOrderFront(nil)
}
