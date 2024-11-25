//  BaseAppCell.swift
//  FleksyApps
// 
//  Copyright © 2023 Thingthing. All rights reserved.
//
    

import UIKit
import FleksyAppsCore

/// Superclass of cells to avoid repeating functionality. The use of this class is not required.
class BaseAppCell<ViewContent: UIView>: UICollectionViewCell {
    
    /// The view that holds the cell's content.
    ///
    /// It's centered vertically and horizontally in the cell and has the same height and width with lower priority. Use required properties to change its height or width, although it will always remain centered in the cell.
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
        
        let leadingConstraint = viewContent.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        leadingConstraint.priority = .defaultHigh
        
        let topConstraint = viewContent.topAnchor.constraint(equalTo: contentView.topAnchor)
        topConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            leadingConstraint,
            viewContent.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor),
            topConstraint,
            viewContent.heightAnchor.constraint(lessThanOrEqualTo: contentView.heightAnchor),
            
            viewContent.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            viewContent.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
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
