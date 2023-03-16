//  GiphyConstants.swift
//  FleksyApps
// 
//  Copyright © 2023 Thingthing. All rights reserved.
//
    

import UIKit
import BaseFleksyApp

public enum GiphyConstants {
    static let logoThumbnailVideoURL = URL(string: "https://s3-eu-west-1.amazonaws.com/tt-fk-static-content/Poweredby_100px_Badge.mp4")!
    static let logoGifURL = URL(string: "https://s3-eu-west-1.amazonaws.com/tt-fk-static-content/Poweredby_100px_Badge.gif")!
    
    enum LocalizedStrings {
        static let trendingCategoryName = NSLocalizedString("Giphy.Category.Trending", value: "Trending", comment: "The title of Trending category")
        static let searchButtonText = NSLocalizedString("Giphy.SearchButtonText", value: "Search on Giphy", comment: "The title of the search button in full cover mode")
        static let searchPlaceHolder = NSLocalizedString("Giphy.SearchPlaceholder", value: "Search for gifs...", comment: "The placeholder of the keyboard textfield")
        static let toastDownloading = NSLocalizedString("Giphy.Toast.Downloading", value: "Downloading", comment: "The text to show in the toast while the gif selected by the user is being downloaded")
        static let toastCopiedAndReady = NSLocalizedString("Giphy.Toast.CopiedAndReady", value: "Copied and ready to paste!", comment: "The text to show in the toast once the selected gif has completed downloading, is copied to the clipboard and ready to be pasted in applications")
        
        static let noGifsError = NSLocalizedString("Giphy.Error.NoGifs", value: "Currently there are no gifs available.", comment: "Represents an error or information about the absence of gifs shown")
        
        static let gifDownloadError = NSLocalizedString("Giphy.Error.download", value: "The gif couldn't download", comment: "The text shown when the user taps a gif but the gif download fails.")
    }
    
    static var giphyAppIcon: UIImage? {
        return UIImage(named: "gifIcon", in: .module, with: nil)
    }
    
    static let mp4MediaExtension = "mp4"
}

