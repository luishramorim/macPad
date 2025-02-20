//
//  WindowManager.swift
//  macPad
//
//  Created by Luis Amorim on 20/02/25.
//

import Cocoa
import SwiftUI
import UniformTypeIdentifiers

/**
 Opens a new window with a TextEditorView hosting the given Document.
 
 - Parameter document: The Document instance to be edited.
 */
func openNewWindow(with document: Document) {
    let hostingController = NSHostingController(rootView: TextEditorView().environmentObject(document))
    let newWindow = NSWindow(contentViewController: hostingController)
    newWindow.title = document.fileURL?.lastPathComponent ?? "Untitled"
    
    // Define the initial window size as 700x400.
    let initialSize = NSSize(width: 700, height: 400)
    newWindow.setContentSize(initialSize)
    
    // Optionally, define a minimum size.
    newWindow.minSize = NSSize(width: 400, height: 300)
    
    // Allow the window to be resizable.
    newWindow.styleMask.insert(.resizable)
    newWindow.titlebarAppearsTransparent = true
    
    // Create a delegate to handle close actions with unsaved changes.
    let windowDelegate = DocumentWindowDelegate(document: document)
    newWindow.delegate = windowDelegate
    
    // Retain the delegate so it isn't deallocated.
    WindowDelegateStorage.shared.delegates.append(windowDelegate)
    
    newWindow.makeKeyAndOrderFront(nil)
}

/**
 Creates a new Document and opens a new window for it.
 */
func newDocument() {
    let doc = Document()
    openNewWindow(with: doc)
}
