//
//  Document.swift
//  macPad
//
//  Created by Luis Amorim on 20/02/25.
//

import Foundation
import SwiftUI

/**
 A model representing the document being edited.
 
 This class holds the text content, an optional file URL, and a flag indicating whether there are unsaved changes.
 */
final class Document: ObservableObject {
    @Published var text: String = "" {
        didSet {
            hasUnsavedChanges = true
        }
    }
    @Published var fileURL: URL? = nil
    @Published var hasUnsavedChanges: Bool = false
}
