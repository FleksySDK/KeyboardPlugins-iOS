//  Toast.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//


import SwiftUI
import FleksyAppsCore

struct Toast: View {
    
    @Binding var showingLoader: Bool
    @Binding var message: String
    @Binding var appTheme: AppTheme
    
    var textColor: Color {
        Color(appTheme.foreground)
    }
    
    var backgroundColor: Color {
        Color(appTheme.bestContrastColorForForeground)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            if showingLoader {
                ActivityIndicator(style: .medium, color: appTheme.foreground, isAnimating: $showingLoader)
                    .transition(.opacity)
            }
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .cornerRadius(4)
        .shadow(color: backgroundColor, radius: 4)
    }
}

struct Toast_Previews: PreviewProvider {
    static var previews: some View {
        Toast(showingLoader: .constant(true),
              message: .constant("Error message"),
              appTheme: .constant(.init(foreground: .red, background: .blue)))
    }
}
