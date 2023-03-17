//  GifContent.swift
//  FleksyApps
//
//  Copyright © 2022 Thingthing. All rights reserved.
//


import Foundation
import BaseFleksyApp


/// The type for the generic type `ContentType` in `BaseApp`.
///
/// - Important: You need not use this type. This type is public only because it conforms to the `BaseContent` protocol declared in the `BaseApp`.
public struct GifContent: BaseContent {
    
    /// A unique identifier of the gif content.
    public var id: String
    var gifURL: URL
    var thumbnailVideo: BaseMedia
    
    /// The media to be shown to the user. For the GiphyApp, this content consists of a low-res video (for better performance).
    public var viewMedia: BaseFleksyApp.BaseMedia { thumbnailVideo }
    
    private static let poweredByGiphyID = "Powered_By_Giphy"
    static let poweredByGiphyGif: GifContent? = {
        let logoVideoMedia = BaseMedia(url: GiphyConstants.logoThumbnailVideoURL,
                                       fileExtension: "mp4",
                                       width: 100,
                                       height: 140,
                                       contentType: .video)
            
        return Self(id: poweredByGiphyID,
                    gifURL: GiphyConstants.logoGifURL,
                    thumbnailVideo: logoVideoMedia)
    }()
}
