//  ActivityIndicator.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//


import SwiftUI

/// A SwiftUI wrapper for `UIActivityIndicator`. Needed for the `Toast` view.
struct ActivityIndicator: UIViewRepresentable {

    let style: UIActivityIndicatorView.Style
    let color: UIColor
    @Binding var isAnimating: Bool

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: style)
        activityIndicator.color = color
        return activityIndicator
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
