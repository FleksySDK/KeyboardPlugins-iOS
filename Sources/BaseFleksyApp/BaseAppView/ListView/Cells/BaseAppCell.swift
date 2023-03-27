//  BaseAppCell.swift
//  FleksyApps
// 
//  Copyright © 2023 Thingthing. All rights reserved.
//
    

import UIKit
import FleksyAppsCore

/// Superclass of cells to avoid repeating functionality. The use of this class is not required.
class BaseAppCell<ViewContent: UIView>: UICollectionViewCell {
    let viewContent = ViewContent()
    private let contentErrorView = UIImageView(image: BaseConstants.Images.previewErrorImage)
    private let loader = UIActivityIndicatorView(style: .medium)
    var fileURL: URL?
    
    var appTheme: AppTheme? {
        didSet {
            backgroundColor = appTheme?.foreground.withAlphaComponent(0.5)
            loader.color = appTheme?.accent
        }
    }
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Cell life cycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentErrorView.isHidden = true
    }
    
    // MARK: - Interface methods
    
    func showLoader() {
        loader.startAnimating()
        contentErrorView.isHidden = true
    }
    
    func hideLoader() {
        loader.stopAnimating()
    }
    
    func showContentError() {
        contentErrorView.isHidden = false
    }
    
    func hideContentError() {
        contentErrorView.isHidden = true
    }
    
    // MARK: - Private methods
    
    private func setup() {
        layer.cornerRadius = 3
        
        viewContent.layer.cornerRadius = 3
        viewContent.layer.masksToBounds = true
        
        loader.hidesWhenStopped = true
        
        contentErrorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentErrorView)
        
        viewContent.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(viewContent)
        
        loader.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(loader)
        
        NSLayoutConstraint.activate([
            viewContent.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            viewContent.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            viewContent.topAnchor.constraint(equalTo: contentView.topAnchor),
            viewContent.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            contentErrorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentErrorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentErrorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentErrorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            loader.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        contentErrorView.contentMode = .center
    }
}
