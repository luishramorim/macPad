//
//  DocumentWindowDelegate.swift
//  macPad
//
//  Created by Luis Amorim on 20/02/25.
//

import Cocoa
import Foundation

/**
 A window delegate that intercepts the close action to warn about unsaved changes.
 
 When a user attempts to close a window with unsaved changes, an alert is presented with options to:
 
 - Save
 - Save As
 - Discard changes
 - Cancel the close action
 */
class DocumentWindowDelegate: NSObject, NSWindowDelegate {
    var document: Document
    
    init(document: Document) {
        self.document = document
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if document.hasUnsavedChanges {
            let alert = NSAlert()
            alert.messageText = "Unsaved Changes"
            alert.informativeText = "You have unsaved changes. Do you want to save, save as, or discard them?"
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Save As")
            alert.addButton(withTitle: "Discard")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn: // Save
                if let url = document.fileURL {
                    do {
                        try document.text.write(to: url, atomically: true, encoding: .utf8)
                        document.hasUnsavedChanges = false
                        sender.title = url.lastPathComponent
                        return true
                    } catch {
                        print("Error saving file: \(error)")
                        return false
                    }
                } else {
                    return saveAs(document: document)
                }
            case .alertSecondButtonReturn: // Save As
                return saveAs(document: document)
            case .alertThirdButtonReturn: // Discard
                return true
            default: // Cancel
                return false
            }
        }
        return true
    }
    
    /**
     Presents a save panel to allow the user to save the document as a new file.
     
     - Parameter document: The Document to be saved.
     - Returns: A Boolean value indicating whether the save was successful.
     */
    func saveAs(document: Document) -> Bool {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = document.fileURL?.lastPathComponent ?? "Untitled.txt"
        if panel.runModal() == .OK, let url = panel.url {
            document.fileURL = url
            do {
                try document.text.write(to: url, atomically: true, encoding: .utf8)
                document.hasUnsavedChanges = false
                if let window = NSApp.keyWindow {
                    window.title = url.lastPathComponent
                }
                return true
            } catch {
                print("Error saving file: \(error)")
                return false
            }
        }
        return false
    }
}
