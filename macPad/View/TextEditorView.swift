//
//  TextEditorView.swift
//  macPad
//
//  Created by Luis Amorim on 20/02/25.
//

import SwiftUI
import UniformTypeIdentifiers

/**
 A view that displays a full‑screen text editor.
 
 The window’s title is updated to the file's name (or “Untitled” if no file is open). The view also shows:
 
 - The last edited date, which is fetched from the file's modification attributes if the document is saved, or the current date if there are unsaved changes.
 - The file name, with an asterisk (*) appended on the right if there are unsaved changes.
 - The file extension (in uppercase) and the character count of the document.
 
 Unsaved changes are tracked locally within this view.

 */
struct TextEditorView: View {
    @EnvironmentObject var document: Document
    @State private var unsavedChanges: Bool = false

    var body: some View {
        TextEditor(text: Binding(
            get: { document.text },
            set: { newValue in
                document.text = newValue
                unsavedChanges = true
            }
        ))
        .font(.system(.body, design: .monospaced))
        .padding([.leading, .top], 10)
        .padding(.bottom, 30)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .onAppear {
            updateWindowTitle()
            // Caso o delegate da janela ativa não seja do tipo DocumentWindowDelegate, atribuí-lo.
            if let window = NSApp.keyWindow, !(window.delegate is DocumentWindowDelegate) {
                let newDelegate = DocumentWindowDelegate(document: document)
                window.delegate = newDelegate
                WindowDelegateStorage.shared.delegates.append(newDelegate)
            }
        }
        .onChange(of: document.fileURL) { _, _ in
            updateWindowTitle()
            // Reset unsavedChanges when the file is saved (i.e., when fileURL changes)
            unsavedChanges = false
        }
        .overlay(
            ZStack {
                Rectangle()
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.gray.opacity(0.3))
                
                HStack {
                    Text("Last edited: \(getLastEditedDate())")
                        .font(.system(.caption2, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Append an asterisk (*) to the right of the file name if there are unsaved changes.
                    Text("\(document.fileURL?.lastPathComponent ?? "Untitled")\(unsavedChanges ? " *" : "")")
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("\(document.fileURL?.pathExtension.uppercased() ?? "Unknown") | \(document.text.count) c")
                        .font(.system(.caption2, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal)
            }
            .frame(height: 30), alignment: .bottom
        )
    }
    
    /**
     Returns the formatted last edited date.
     
     If there are unsaved changes, it returns the current date and time.
     If the document is saved, it retrieves the file's modification date from the file attributes.
     
     - Returns: A `String` representing the last edited date.
     */
    func getLastEditedDate() -> String {
        if unsavedChanges {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: Date())
        } else if let fileURL = document.fileURL {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                if let modificationDate = attributes[.modificationDate] as? Date {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    return formatter.string(from: modificationDate)
                }
            } catch {
                print("Error retrieving file attributes: \(error)")
            }
            return "Unknown"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: Date())
        }
    }
    
    /**
     Updates the window title based on the document's file URL.
     
     If the document is saved, the window title will display the file's name.
     Otherwise, it will display "Untitled".
     */
    private func updateWindowTitle() {
        if let window = NSApp.keyWindow {
            window.title = document.fileURL?.lastPathComponent ?? "Untitled"
        }
    }
}

#Preview {
    TextEditorView().environmentObject(Document())
}
