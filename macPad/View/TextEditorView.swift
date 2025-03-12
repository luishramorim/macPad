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
    
    /// The text to show in the Markdown or HTML preview.
    @State private var previewText: String = ""
    
    /// Determines if the file is a Markdown file based on its extension.
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
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                textEditorContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if (isMarkdown || isHTML), showPreview {
                    Divider()
                    
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
                        HTMLPreview(htmlContent: previewText)
                            .padding(.bottom, 30)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(previewLabelOverlay, alignment: .bottom)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            updateWindowTitle()
            previewText = document.text.isEmpty
                ? "## Hello World\n\nRender Markdown text in SwiftUI."
                : document.text
        }
        .onChange(of: document.text) { _, newValue in
            previewText = newValue.isEmpty
                ? "## Hello World\n\nRender Markdown text in SwiftUI."
                : newValue
        }
        .onChange(of: document.fileURL) { _, _ in
            updateWindowTitle()
            unsavedChanges = false
            document.hasUnsavedChanges = false
        }
    }
    
    var textEditorContent: some View {
        TextEditor(text: Binding(
            get: { document.text },
            set: { newValue in
                document.text = newValue
                previewText = newValue
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
        .overlay(
            ZStack {
                Rectangle()
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.tertiary)
                
                HStack {
                    Text("Last edited: \(getLastEditedDate())")
                        .font(.system(.caption2, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(document.fileURL?.lastPathComponent ?? "Untitled")\(document.hasUnsavedChanges ? " *" : "")")
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("\(fileTypeLabel) | \(document.text.count) c")
                        .font(.system(.caption2, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
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
            if let window = window, !(window.delegate is DocumentWindowDelegate) {
                let newDelegate = DocumentWindowDelegate(document: document)
                window.delegate = newDelegate
                WindowDelegateStorage.shared.delegates.append(newDelegate)
                window.isDocumentEdited = document.hasUnsavedChanges
            }
        })
    }
    
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
    
    private func updateWindowTitle() {
        if let window = NSApp.keyWindow {
            window.title = document.fileURL?.lastPathComponent ?? "Untitled"
            window.isDocumentEdited = document.hasUnsavedChanges
        }
    }
}

#Preview {
    TextEditorView().environmentObject(Document())
}