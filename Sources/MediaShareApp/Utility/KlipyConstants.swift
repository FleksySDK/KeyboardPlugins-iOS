//  MediaShareConstants.swift
//  FleksyApps
//
//  Copyright © 2024 Thingthing. All rights reserved.
//
    

import UIKit
import BaseFleksyApp
import AVKit
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

enum MediaShareConstants {
    
    enum LocalizedStrings {
        static let trendingCategoryName = NSLocalizedString("MediaShare.Category.Trending", value: "Trending", comment: "The title of Trending category")
        static let searchGifsPlaceHolder = NSLocalizedString("MediaShare.SearchPlaceholder", value: "Search for gifs...", comment: "The placeholder of the keyboard textfield for gifs")
        static let searchClipsPlaceHolder = NSLocalizedString("MediaShare.SearchPlaceholder", value: "Search for clips...", comment: "The placeholder of the keyboard textfield for clips")
        static let searchStickersPlaceHolder = NSLocalizedString("MediaShare.SearchPlaceholder", value: "Search for stickers...", comment: "The placeholder of the keyboard textfield for stickers")
        static let toastDownloading = NSLocalizedString("MediaShare.Toast.Downloading", value: "Downloading", comment: "The text to show in the toast while the media content selected by the user is being downloaded")
        static let toastCopiedAndReady = NSLocalizedString("MediaShare.Toast.CopiedAndReady", value: "Copied and ready to paste!", comment: "The text to show in the toast once the selected media content has completed downloading, is copied to the clipboard and ready to be pasted in applications")
        static let contentDownloadError = NSLocalizedString("MediaShare.Error.download", value: "The item couldn't download", comment: "The text shown when the user taps a media content but its download fails")
    }
    
    
    static func appIcon(for contentType: MediaShareApp.ContentType) -> UIImage? {
        let systemImageName = switch contentType {
        case .clips: "video.circle"
        case .gifs: "photo.on.rectangle.angled"
        case .stickers: "photo"
        }
        return UIImage(systemName: systemImageName)
    }
    
    static let mp4MediaExtension = "mp4"
    static let webpMediaExtension = "webp"
    
    static let mp4PasteboardType: String = AVFileType.mp4.rawValue
    static let webpPasteboardType: String = if #available(iOS 14.0, *) {
#if canImport(UniformTypeIdentifiers)
        UTType.webP.identifier
#else
        ""
#endif
    } else {
        ""
    }
    
    static let gifPasteboardType: String = if #available(iOS 14.0, *) {
#if canImport(UniformTypeIdentifiers)
        UTType.gif.identifier
#else
        "com.compuserve.gif"
#endif
    } else {
        "com.compuserve.gif"
    }
    
    
}

