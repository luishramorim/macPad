//
//  WindowDelegateStorage.swift
//  macPad
//
//  Created by Luis Amorim on 20/02/25.
//

import AppKit

/**
 A singleton used to retain window delegates.
 
 Since NSWindow.delegate is a weak reference, storing delegates here ensures they remain alive
 while their corresponding windows are open.
 */
class WindowDelegateStorage {
    static let shared = WindowDelegateStorage()
    var delegates: [DocumentWindowDelegate] = []
    private init() {}
}
