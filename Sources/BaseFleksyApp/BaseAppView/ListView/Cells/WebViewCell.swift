//  WebViewCell.swift
//  FleksyApps
//
//  Copyright © 2024 Thingthing. All rights reserved.
//

import UIKit
import WebKit
import FleksyAppsCore

class WebViewCell: BaseAppCell<WKWebView> {
    
    private var webView: WKWebView { viewContent }
    
    private var expectedContentSize: CGSize?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        webView.navigationDelegate = self
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.isOpaque = false
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @MainActor
    func loadHTML(_ html: String, expectedContentSize: CGSize? = nil) {
        self.expectedContentSize = expectedContentSize
        webView.loadHTMLString(html, baseURL: nil)
        webView.scrollView.isScrollEnabled = false
        hideContentError()
    }
    
    override var frame: CGRect {
        didSet {
            computeWebViewScaleFactor()
        }
    }
    
    override var bounds: CGRect {
        didSet {
            computeWebViewScaleFactor()
        }
    }
    
    override var appTheme: AppTheme? {
        didSet {
            backgroundColor = .clear
        }
    }
    
    private func computeWebViewScaleFactor() {
        var scaleFactor: CGFloat = 1
        var contentSize = bounds.size
        if let expectedContentSize {
            scaleFactor = min(bounds.width / expectedContentSize.width, bounds.height / expectedContentSize.height)
            contentSize = expectedContentSize.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
            setSizeConstraints(contentSize)
        } else {
            removeSizeConstraints()
        }
        if #available(iOS 14.0, *) {
            webView.pageZoom = scaleFactor
        }
    }
    
    private var heightConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?
    
    private func setSizeConstraints(_ size: CGSize) {
        if let heightConstraint {
            heightConstraint.constant = size.height
        } else {
            heightConstraint = webView.heightAnchor.constraint(equalToConstant: size.height)
        }
        heightConstraint?.isActive = true
        
        if let widthConstraint {
            widthConstraint.constant = size.width
        } else {
            widthConstraint = webView.widthAnchor.constraint(equalToConstant: size.width)
        }
        widthConstraint?.isActive = true
    }
    
    private func removeSizeConstraints() {
        heightConstraint?.isActive = false
        heightConstraint = nil
        widthConstraint?.isActive = false
        widthConstraint = nil
    }
}

extension WebViewCell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else {
            return .allow
        }
        if navigationAction.navigationType == .linkActivated {
            await UIApplication.shared.open(url)
            return .cancel
        } else {
            return .allow
        }
    }
}
