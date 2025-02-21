//
//  AboutView.swift
//  macPad
//
//  Created by Luis Amorim on 20/02/25.
//

import SwiftUI

/**
 A view that displays custom information about the application.
 
 This view serves as the content for the custom About window.
 */
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("Icon")
                .resizable()
                .frame(width: 100, height: 100)
            
            Text("macPad")
                .font(.largeTitle)
                .bold()
            
            Text("Version 1.1")
                .font(.headline)
            
            Text("Developed by Luis Amorim")
                .font(.subheadline)
            
            Text("© 2025 All Rights Reserved")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

#if DEBUG
#Preview {
    AboutView()
}
#endif
