//
//  WindowManager.swift
//  macPad
//
//  Created by Luis Amorim on 20/02/25.
//

import Cocoa
import SwiftUI
import UniformTypeIdentifiers

/// Tracks the origin of the last opened window to cascade new windows.
private var lastWindowOrigin: NSPoint?

/**
 Opens a new window with a TextEditorView hosting the given Document.
 
 The first window is centered on the screen, and subsequent windows are cascaded (offset slightly to the right and downward).
 
 - Parameter document: The Document instance to be edited.
 */
func openNewWindow(with document: Document) {
    let hostingController = NSHostingController(rootView: TextEditorView().environmentObject(document))
    let newWindow = NSWindow(contentViewController: hostingController)
    newWindow.title = document.fileURL?.lastPathComponent ?? "Untitled"
    
    // Define the initial window size as 700x400.
    let initialSize = NSSize(width: 700, height: 400)
    newWindow.setContentSize(initialSize)
    
    // Set a minimum window size.
    newWindow.minSize = NSSize(width: 400, height: 300)
    
    // Allow the window to be resizable and set a transparent title bar.
    newWindow.styleMask.insert(.resizable)
    newWindow.titlebarAppearsTransparent = true
    
    // Create a delegate to handle close actions with unsaved changes.
    let windowDelegate = DocumentWindowDelegate(document: document)
    newWindow.delegate = windowDelegate
    WindowDelegateStorage.shared.delegates.append(windowDelegate)
    
    // Position the new window:
    if let lastOrigin = lastWindowOrigin {
        // Cascade: offset by 30 points to the right and 30 points down.
        let newOrigin = NSPoint(x: lastOrigin.x + 30, y: lastOrigin.y - 30)
        newWindow.setFrameOrigin(newOrigin)
        lastWindowOrigin = newWindow.frame.origin
    } else {
        // For the first window, center it on the screen.
        newWindow.center()
        lastWindowOrigin = newWindow.frame.origin
    }
    
    newWindow.makeKeyAndOrderFront(nil)
}

/**
 Creates a new Document and opens a new window for it.
 */
func newDocument() {
    let doc = Document()
    openNewWindow(with: doc)
}
