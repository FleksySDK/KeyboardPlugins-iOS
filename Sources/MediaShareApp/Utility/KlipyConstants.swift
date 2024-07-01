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

protocol MediaShareAppLocalizedString {
    static var gifs: String { get }
    static var clips: String { get }
    static var stickers: String { get }
}

extension MediaShareAppLocalizedString {
    static func get(for contentType: MediaShareApp.ContentType) -> String {
        switch contentType {
        case .clips: return clips
        case .gifs: return gifs
        case .stickers: return stickers
        }
    }
}

enum MediaShareConstants {
    
    enum LocalizedStrings {
        
        enum trendingCategoryName: MediaShareAppLocalizedString {
            static var gifs = NSLocalizedString("MediaShare.Category.Trending.gifs", value: "Trending", comment: "The title of Trending category for the gifs MediaShareApp")
            static var clips = NSLocalizedString("MediaShare.Category.Trending.clips", value: "Trending", comment: "The title of Trending category for the clips MediaShareApp")
            static var stickers = NSLocalizedString("MediaShare.Category.Trending.stickers", value: "Trending", comment: "The title of Trending category for the stickers MediaShareApp")
        }
        enum searchPlaceHolder: MediaShareAppLocalizedString {
            static var gifs = NSLocalizedString("MediaShare.SearchPlaceholder.gifs", value: "Search for gifs...", comment: "The placeholder of the keyboard textfield for gifs")
            static var clips = NSLocalizedString("MediaShare.SearchPlaceholder.clips", value: "Search for clips...", comment: "The placeholder of the keyboard textfield for clips")
            static var stickers = NSLocalizedString("MediaShare.SearchPlaceholder.stickers", value: "Search for stickers...", comment: "The placeholder of the keyboard textfield for stickers")
        }
        enum searchButtonText: MediaShareAppLocalizedString {
            static var gifs = NSLocalizedString("MediaShare.SearchButtonText.gifs", value: "Search for gifs...", comment: "The title of the search button for gifs in full cover mode")
            static var clips = NSLocalizedString("MediaShare.SearchButtonText.clips", value: "Search for clips...", comment: "The title of the search button for clips in full cover mode")
            static var stickers = NSLocalizedString("MediaShare.SearchButtonText.stickers", value: "Search for stickers...", comment: "The title of the search button for stickers in full cover mode")
        }
        enum toastDownloading: MediaShareAppLocalizedString {
            static var gifs = NSLocalizedString("MediaShare.Toast.Downloading.gifs", value: "Downloading", comment: "The text to show in the toast while the gif selected by the user is being downloaded")
            static var clips = NSLocalizedString("MediaShare.Toast.Downloading.clips", value: "Downloading", comment: "The text to show in the toast while the clip selected by the user is being downloaded")
            static var stickers = NSLocalizedString("MediaShare.Toast.Downloading.stickers", value: "Downloading", comment: "The text to show in the toast while the sticker selected by the user is being downloaded")
        }
        enum toastCopiedAndReady: MediaShareAppLocalizedString {
            static var gifs = NSLocalizedString("MediaShare.Toast.CopiedAndReady.gifs", value: "Copied and ready to paste!", comment: "The text to show in the toast once the selected gif has completed downloading, is copied to the clipboard and ready to be pasted in applications")
            static var clips: String = NSLocalizedString("MediaShare.Toast.CopiedAndReady.gifs", value: "Copied and ready to paste!", comment: "The text to show in the toast once the selected clip has completed downloading, is copied to the clipboard and ready to be pasted in applications")
            static var stickers: String = NSLocalizedString("MediaShare.Toast.CopiedAndReady.gifs", value: "Copied and ready to paste!", comment: "The text to show in the toast once the selected sticker has completed downloading, is copied to the clipboard and ready to be pasted in applications")
        }
        enum contentDownloadError: MediaShareAppLocalizedString {
            static var gifs = NSLocalizedString("MediaShare.Error.download.gifs", value: "The gif couldn't download", comment: "The text shown when the user taps a gif but its download fails")
            static var clips = NSLocalizedString("MediaShare.Error.download.clips", value: "The clip couldn't download", comment: "The text shown when the user taps a clip but its download fails")
            static var stickers = NSLocalizedString("MediaShare.Error.download.stickers", value: "The sticker couldn't download", comment: "The text shown when the user taps a sticker but its download fails")
        }
    }
    
    
    static func appIcon(for contentType: MediaShareApp.ContentType) -> UIImage? {
        let systemImageName = switch contentType {
        case .clips: "video.circle"
        case .gifs: "gifIcon"
        case .stickers: "photo.on.rectangle.angled"
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

