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

 This function creates an NSWindow hosting the AboutView, configures its appearance,
 calculates its position so that it is centered on the main screen, and makes it key and visible.
 */
func showAboutWindow() {
    // Create the hosting controller with AboutView.
    let hostingController = NSHostingController(rootView: AboutView())
    
    // Create a new window for the about content.
    let aboutWindow = NSWindow(contentViewController: hostingController)
    aboutWindow.title = "About macPad"
    aboutWindow.styleMask = [.titled, .closable, .miniaturizable]
    aboutWindow.isReleasedWhenClosed = false  // Keep the window in memory if needed.
    
    // Activate the app to ensure the window is visible.
    NSApp.activate(ignoringOtherApps: true)
    
    // Calculate the center of the main screen and set the window's origin accordingly.
    if let screenFrame = NSScreen.main?.frame {
        // Get the window's current size (after layout, if needed you can set a specific size)
        let windowSize = aboutWindow.frame.size
        let newOrigin = NSPoint(
            x: (screenFrame.width - windowSize.width) / 2,
            y: (screenFrame.height - windowSize.height) / 2
        )
        aboutWindow.setFrameOrigin(newOrigin)
    }
    
    aboutWindow.makeKeyAndOrderFront(nil)
}
