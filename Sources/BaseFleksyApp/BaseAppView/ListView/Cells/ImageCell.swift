//  ImageCell.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//


import UIKit
import FleksyAppsCore

class ImageCell: BaseAppCell<UIImageView> {
    
    private var imageView: UIImageView { viewContent }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    // MARK: - Interface methods
    
    /// It could happen that there's no file at `localURL` yet. In that case, calling this method shows the loader in the cell.
    /// - Parameter localURL: The url to the local image.
    /// - Returns: Whether or not the image in the given url was loaded.
    @MainActor
    func loadImage(localURL: URL) -> Bool {
        fileURL = localURL
        hideContentError()
        let imageLoaded = setImageFromFileAt(url: localURL)
        if imageLoaded {
            hideLoader()
        } else {
            showLoader()
        }
        return imageLoaded
    }
    
    
    /// Calling this method makes the cell show the image from the passed url only if it matches the url passed in the `loadImage(localURL:)` method. Otherwise, this call is ignored (since it corresponds to a previous url before the cell has been reused)
    /// If the urls match but there's no file in the url, then it's treated as an error and a error image is shown
    /// - Parameter localURL: The url to the local image.
    @MainActor
    func forceLoadImage(localURL: URL) {
        guard localURL == self.fileURL else {
            return
        }
        let imageLoaded = setImageFromFileAt(url: localURL)
        hideLoader()
        if imageLoaded {
            hideContentError()
        } else {
            showContentError()
        }
    }
    
    // MARK: - Private methods
    
    @MainActor
    private func setImageFromFileAt(url: URL) -> Bool {
        imageView.image = UIImage(contentsOfFile: url.path)
        return imageView.image != nil
    }
}
