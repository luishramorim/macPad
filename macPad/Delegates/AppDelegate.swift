//
//  AppDelegate.swift
//  macPad
//
//  Created by Luis Amorim on 20/02/25.
//

import Cocoa
import SwiftUI
import UniformTypeIdentifiers

/**
 A custom AppDelegate for the macPad application.
 
 This delegate handles application-level events, including opening files directly from the system.
 If a file is opened externally (e.g., via Finder), a new window is created for the file.
 */
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Do not open a default window on launch.
    }
    
    /**
     Handles file open requests from the system.
     
     - Parameters:
       - sender: The NSApplication instance.
       - filename: The path of the file to open.
     - Returns: A Boolean value indicating whether the file was successfully handled.
     */
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        let doc = Document()
        doc.fileURL = url
        do {
            doc.text = try String(contentsOf: url, encoding: .utf8)
            doc.hasUnsavedChanges = false
        } catch {
            print("Error opening file: \(error)")
        }
        openNewWindow(with: doc)
        return true
    }
}
