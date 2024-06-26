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
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @MainActor
    func loadHTML(_ html: String, expectedContentSize: CGSize? = nil) {
        self.expectedContentSize = expectedContentSize
        webView.loadHTMLString(html, baseURL: nil)
        webView.scrollView.isScrollEnabled = false
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
    
    private func computeWebViewScaleFactor() {
        var scaleFactor: CGFloat = 1
        if let expectedContentSize {
            scaleFactor = bounds.size.width / expectedContentSize.width
        }
        if #available(iOS 14.0, *) {
            webView.pageZoom = scaleFactor
        }
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
