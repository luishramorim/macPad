//
//  macPadApp.swift
//  macPad
//
//  Created by Luis Amorim on 20/02/25.
//

import SwiftUI
import UniformTypeIdentifiers

/**
 The main entry point for the macPad application.
 
 This application supports multiple document windows. Each window hosts a separate Document instance
 displayed in a TextEditorView. The File menu provides commands for:
 
 - Creating a new file (New File)
 - Opening an existing file (Open File)
 - Saving the current document (Save File)
 - Saving the current document as a new file (Save As)
 
 The app can open files directly from the system (e.g., via Finder).
 If no file is opened at startup, no editor window is created until the user creates or opens a file.
 
 Additionally, a custom About window can be displayed via the About menu command.
 */
@main
struct macPadApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // The Settings scene is used here to manage global commands.
        // Applying a hidden title bar style hides the window title
        // while keeping the action buttons available.
        Settings {
            EmptyView()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                Button("New File") {
                    newDocument()
                }
                .keyboardShortcut("N", modifiers: .command)
                
                Button("Open File") {
                    // Call openFile without a URL; this will present an open panel.
                    openFile()
                }
                .keyboardShortcut("O", modifiers: .command)
                
                Button("Save File") {
                    saveFile()
                }
                .keyboardShortcut("S", modifiers: .command)
                
                Button("Save As") {
                    saveAsFile()
                }
                .keyboardShortcut("S", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button("About macPad") {
                    showAboutWindow()
                }
            }
        }
    }
    
    // MARK: - File Menu Actions
    
    /**
     Creates a new document and opens a new window for it.
     */
    private func newDocument() {
        let doc = Document()
        openNewWindow(with: doc)
    }
    
    /**
     Opens a file either using a URL selected by the system or by presenting an open panel.
     
     This function checks if a file URL was provided by the system (e.g., via Finder). If so,
     it uses that URL to load the document; otherwise, it presents an NSOpenPanel to allow the user
     to select a file. Once the file is selected and loaded, a new window is opened with the document.
     
     - Parameter selectedURL: An optional file URL provided by the system. Defaults to `nil`.
     */
    private func openFile(with selectedURL: URL? = nil) {
        let fileURL: URL?
        
        if let selectedURL = selectedURL {
            // Use the file URL provided by the system.
            fileURL = selectedURL
        } else {
            // Present an open panel to let the user select a file.
            let panel = NSOpenPanel()
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            panel.allowedContentTypes = [UTType.text]
            
            if panel.runModal() == .OK {
                fileURL = panel.url
            } else {
                fileURL = nil
            }
        }
        
        // Proceed only if a file URL is available.
        guard let url = fileURL else { return }
        
        let doc = Document()
        doc.fileURL = url
        do {
            doc.text = try String(contentsOf: url, encoding: .utf8)
            doc.hasUnsavedChanges = false
        } catch {
            print("Error opening file: \(error)")
        }
        openNewWindow(with: doc)
    }
    
    /**
     Saves the document of the currently selected (key) window.
     
     If the document already has an associated file URL, the content is written directly.
     Otherwise, the Save As workflow is triggered.
     */
    private func saveFile() {
        guard let window = NSApp.keyWindow else {
            print("No active window found.")
            return
        }
        guard let delegate = window.delegate as? DocumentWindowDelegate else {
            print("Active window delegate is not of type DocumentWindowDelegate.")
            return
        }
        let doc = delegate.document
        if let url = doc.fileURL {
            do {
                try doc.text.write(to: url, atomically: true, encoding: .utf8)
                doc.hasUnsavedChanges = false
                window.title = url.lastPathComponent
                window.isDocumentEdited = false
            } catch {
                print("Error saving file: \(error)")
            }
        } else {
            _ = delegate.saveAs(document: doc)
        }
    }
    
    /**
     Triggers the Save As workflow for the document of the key window.
     */
    private func saveAsFile() {
        guard let window = NSApp.keyWindow,
              let delegate = window.delegate as? DocumentWindowDelegate else { return }
        _ = delegate.saveAs(document: delegate.document)
    }
}
