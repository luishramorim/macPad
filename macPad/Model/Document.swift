//
//  Document.swift
//  macPad
//
//  Created by Luis Amorim on 20/02/25.
//

import Foundation
import SwiftUI

/**
 A model that represents the document being edited.
 
 This class holds the text content and an optional file URL. It is used by both the
 text editor view and the app's menu commands.
 
 - Author: Luis H. Ramorim
 - Since: macOS 12.0
 */
final class Document: ObservableObject {
    /// The content of the document.
    @Published var text: String = ""
    /// The URL of the document file. If nil, the document is unsaved.
    @Published var fileURL: URL? = nil
}
