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
 When a user selects "Open With" for a supported file, the system calls this method, and a new window is created for each file.
 Ensure that your Info.plist declares the supported document types.
 */
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Do not open a default window on launch.
    }
    
    /**
     Handles file open requests from the system.
     
     This method is called with an array of file paths (filenames) when the app is asked to open files.
     
     - Parameters:
       - sender: The NSApplication instance.
       - filenames: An array of file paths to open.
     */
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        for filename in filenames {
            let url = URL(fileURLWithPath: filename)
            let doc = Document()
            doc.fileURL = url
            do {
                doc.text = try String(contentsOf: url, encoding: .utf8)
                doc.hasUnsavedChanges = false
            } catch {
                print("Error opening file: \(error)")
            }
            // Use the WindowManager function to open a new window with the document.
            openNewWindow(with: doc)
        }
        // Indicate success to the system.
        sender.reply(toOpenOrPrint: .success)
    }
}
