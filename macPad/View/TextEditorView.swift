//
//  TextEditorView.swift
//  macPad
//
//  Created by Luis Amorim on 20/02/25.
//

import SwiftUI
import UniformTypeIdentifiers
import MarkdownUI  // For Markdown preview
import WebKit      // For HTML preview

/**
 A view that displays a text editor and, if the file is Markdown or HTML, optionally a preview side by side.

 - The editor and preview automatically fill the entire window space.
 - A toggle button in the bottom overlay of the text editor shows/hides the preview if the file is ".md", ".html", or ".htm".
 - The overlay shows the last edited date (Today, Yesterday, or formatted as "dd/MM/yy - HH:mm"),
   file name (with an asterisk " *" if there are unsaved changes), and character count.
 */
struct TextEditorView: View {
    @EnvironmentObject var document: Document
    @State private var unsavedChanges: Bool = false
    
    /// The text to show in the preview (Markdown or HTML).
    @State private var previewText: String = ""
    
    /// Determines if the file is Markdown based on its extension.
    var isMarkdown: Bool {
        return document.fileURL?.pathExtension.lowercased() == "md"
    }
    
    /// Determines if the file is HTML based on its extension.
    var isHTML: Bool {
        guard let ext = document.fileURL?.pathExtension.lowercased() else { return false }
        return ["html", "htm"].contains(ext)
    }
    
    /// Controls whether the preview is visible.
    @State private var showPreview: Bool = true
    
    /// A computed label for the file type in the bottom overlay.
    private var fileTypeLabel: String {
        if isMarkdown {
            return "Markdown"
        } else if isHTML {
            return "HTML"
        } else {
            return document.fileURL?.pathExtension.uppercased() ?? "Unknown"
        }
    }
    
    var body: some View {
        // The main vertical stack filling all space.
        VStack(spacing: 0) {
            // The horizontal stack for the editor (always) and preview (if shown).
            HStack(spacing: 0) {
                textEditorContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if (isMarkdown || isHTML), showPreview {
                    Divider()
                    
                    // Show either Markdown or HTML preview side by side.
                    if isMarkdown {
                        ScrollView {
                            Markdown(previewText)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.primary)
                        }
                        .padding(.bottom, 30)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(previewLabelOverlay, alignment: .bottom)
                        
                    } else if isHTML {
                        // HTML preview using a WebView
                        HTMLPreview(htmlContent: previewText)
                            .padding(.bottom, 30)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(previewLabelOverlay, alignment: .bottom)
                    }
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
                    .foregroundStyle(.tertiary)
                
                // Horizontal info bar.
                HStack {
                    Text("Last edited: \(getLastEditedDate())")
                        .font(.system(.caption2, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(document.fileURL?.lastPathComponent ?? "Untitled")\(document.hasUnsavedChanges ? " *" : "")")
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Show the file type label ("Markdown", "HTML", or extension) plus character count.
                    Text("\(fileTypeLabel) | \(document.text.count) c")
                        .font(.system(.caption2, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    // If this is a Markdown or HTML file, show the preview toggle button.
                    if isMarkdown || isHTML {
                        Button {
                            showPreview.toggle()
                        } label: {
                            Image(systemName: showPreview
                                  ? "inset.filled.lefthalf.arrow.left.rectangle"
                                  : "inset.filled.righthalf.arrow.right.rectangle")
                                .font(.headline)
                        }
                        .help("Toggle Preview")
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
    
    /// An overlay labeling the preview area with a simple "Preview" strip at the bottom.
    private var previewLabelOverlay: some View {
        ZStack {
            Rectangle()
                .frame(maxWidth: .infinity)
                .foregroundStyle(.tertiary).opacity(1.0)
            
            HStack {
                Text("Preview")
                    .font(.system(.caption2, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(height: 30)
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
 A helper view that embeds a WKWebView for displaying HTML content in SwiftUI.
 */
struct HTMLPreview: NSViewRepresentable {
    let htmlContent: String
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(htmlContent, baseURL: nil)
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
