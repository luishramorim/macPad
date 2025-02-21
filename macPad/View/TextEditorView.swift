//
//  TextEditorView.swift
//  macPad
//
//  Created by Luis Amorim on 20/02/25.
//

import SwiftUI
import UniformTypeIdentifiers
import MarkdownUI // Using the swiftui-markdown package

/**
 A view that displays a text editor and, if the file is Markdown, optionally a Markdown preview side by side.
 
 - The editor and preview automatically fill the entire window space (no explicit window resizing).
 - A toggle button in the bottom overlay of the text editor shows/hides the Markdown preview if the file is ".md".
 - The window's title is updated to the file name; the overlay shows the last edited date (Today, Yesterday, or formatted as "dd/MM/yy - HH:mm"),
   file name (with an asterisk " *" if there are unsaved changes), and character count.
 */
struct TextEditorView: View {
    @EnvironmentObject var document: Document
    @State private var unsavedChanges: Bool = false
    
    /// The text to show in the Markdown preview.
    @State private var previewText: String = ""
    
    /// Determines if the file is a Markdown file based on its extension.
    var isMarkdown: Bool {
        return document.fileURL?.pathExtension.lowercased() == "md"
    }
    
    /// Controls whether the Markdown preview is visible.
    @State private var showPreview: Bool = true
    
    var body: some View {
        // The main vertical stack filling all space.
        VStack(spacing: 0) {
            // The horizontal stack for the editor (always) and preview (if shown).
            HStack(spacing: 0) {
                textEditorContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if isMarkdown && showPreview {
                    Divider()
                    
                    ScrollView {
                        Markdown(previewText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 30)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        ZStack {
                            // Semi-transparent background strip.
                            Rectangle()
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.gray.opacity(0.3))
                            
                            HStack{
                                Text("Preview")
                                    .font(.system(.caption2, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            
                        }
                            .frame(height: 30), alignment: .bottom
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 500, minHeight: 400) // A basic minimum size for convenience.
        .onAppear {
            updateWindowTitle()
            // Initialize the preview text from the document, or use a default for empty docs.
            previewText = document.text.isEmpty
                ? "## Hello World\n\nRender Markdown text in SwiftUI."
                : document.text
        }
        .onChange(of: document.text) { _, newValue in
            // Keep the preview text in sync with the document.
            previewText = newValue.isEmpty
                ? "## Hello World\n\nRender Markdown text in SwiftUI."
                : newValue
        }
        .onChange(of: document.fileURL) { _, _ in
            // Reset unsaved changes whenever a new file is loaded.
            updateWindowTitle()
            unsavedChanges = false
            document.hasUnsavedChanges = false
        }
    }
    
    /// The main text editor content, with an overlay showing file details and a toggle button.
    var textEditorContent: some View {
        TextEditor(text: Binding(
            get: { document.text },
            set: { newValue in
                document.text = newValue
                previewText = newValue // Keep preview in sync as user types.
                unsavedChanges = true
                document.hasUnsavedChanges = true
                if let window = NSApp.keyWindow {
                    window.isDocumentEdited = true
                }
            }
        ))
        .font(.system(.body, design: .monospaced))
        .padding([.leading, .top], 10)
        .padding(.bottom, 30)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        // Overlay for file info + toggle button at bottom of text editor.
        .overlay(
            ZStack {
                // Semi-transparent background strip.
                Rectangle()
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.gray.opacity(0.3))
                
                // Horizontal info bar.
                HStack {
                    Text("Last edited: \(getLastEditedDate())")
                        .font(.system(.caption2, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(document.fileURL?.lastPathComponent ?? "Untitled")\(document.hasUnsavedChanges ? " *" : "")")
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Show "Markdown" if the file is Markdown, otherwise show the extension.
                    Text("\(isMarkdown ? "Markdown" : (document.fileURL?.pathExtension.uppercased() ?? "Unknown")) | \(document.text.count) c")
                        .font(.system(.caption2, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    // If this is a Markdown file, show the preview toggle button.
                    if isMarkdown {
                        Button {
                            showPreview.toggle()
                        } label: {
                            Image(systemName: showPreview
                                  ? "inset.filled.lefthalf.arrow.left.rectangle"
                                  : "inset.filled.righthalf.arrow.right.rectangle")
                                .font(.headline)
                        }
                        .help("Toggle Markdown Preview")
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 30), alignment: .bottom
        )
        .background(WindowAccessor { window in
            // Attach a custom window delegate if none is set.
            if let window = window, !(window.delegate is DocumentWindowDelegate) {
                let newDelegate = DocumentWindowDelegate(document: document)
                window.delegate = newDelegate
                WindowDelegateStorage.shared.delegates.append(newDelegate)
                window.isDocumentEdited = document.hasUnsavedChanges
            }
        })
    }
    
    /**
     Returns the formatted last edited date.
     
     - If the file was modified today, returns "Today".
     - If it was modified yesterday, returns "Yesterday".
     - Otherwise, returns the date formatted as "dd/MM/yy - HH:mm".
     */
    func getLastEditedDate() -> String {
        let now = Date()
        let calendar = Calendar.current
        
        if let fileURL = document.fileURL {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                if let modificationDate = attributes[.modificationDate] as? Date {
                    if calendar.isDateInToday(modificationDate) {
                        return "Today"
                    } else if calendar.isDateInYesterday(modificationDate) {
                        return "Yesterday"
                    } else {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd/MM/yy - HH:mm"
                        return formatter.string(from: modificationDate)
                    }
                }
            } catch {
                print("Error retrieving file attributes: \(error)")
            }
            return "Unknown"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yy - HH:mm"
            return formatter.string(from: now)
        }
    }
    
    /**
     Updates the window title and the document edited indicator based on the document's file URL.
     */
    private func updateWindowTitle() {
        if let window = NSApp.keyWindow {
            window.title = document.fileURL?.lastPathComponent ?? "Untitled"
            window.isDocumentEdited = document.hasUnsavedChanges
        }
    }
}

/**
 A helper view that captures the NSWindow associated with this view.
 
 The `onWindow` closure is called once the NSWindow is available.
 */
struct WindowAccessor: NSViewRepresentable {
    var onWindow: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            onWindow(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

#Preview {
    TextEditorView().environmentObject(Document())
}
