//  ToastContainer.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//


import SwiftUI
import FleksyAppsCore

struct ToastContainer: View {
    
    @MainActor
    fileprivate class ViewModel: ObservableObject {
        @Published var appTheme: AppTheme
        @Published var message: String
        @Published var alignment: Alignment
        @Published var showingLoader: Bool
        
        init(appTheme: AppTheme, message: String = "", alignment: Alignment = .top, showingLoader: Bool = true) {
            self.appTheme = appTheme
            self.message = message
            self.alignment = alignment
            self.showingLoader = showingLoader
        }
    }
    
    @ObservedObject private var viewModel: ViewModel
    
    fileprivate init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    init(appTheme: AppTheme) {
        self.viewModel = ViewModel(appTheme: appTheme)
    }
    
    func update(message: String, alignment: Alignment, showingLoader: Bool, animated: Bool) {
        let changes = {
            self.viewModel.message = message
            self.viewModel.alignment = alignment
            self.viewModel.showingLoader = showingLoader
        }
        if animated {
            withAnimation(.easeInOut, changes)
        } else {
            changes()
        }
    }
    
    var body: some View {
        Color.black
            .opacity(0.25)
            .overlay(
                Toast(showingLoader: $viewModel.showingLoader, message: $viewModel.message, appTheme: $viewModel.appTheme)
                    .padding(),
                alignment: viewModel.alignment
            )
    }
}

struct ToastContainer_Previews: PreviewProvider {
    static var previews: some View {
        ToastContainer(viewModel: ToastContainer.ViewModel(appTheme: .init(foreground: .black, background: .lightGray, accent: .white),
                                                           message: "Hello there!"))
    }
}
