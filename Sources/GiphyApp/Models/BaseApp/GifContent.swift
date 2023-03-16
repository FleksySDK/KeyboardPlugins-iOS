//  GifContent.swift
//  FleksyApps
//
//  Copyright © 2022 Thingthing. All rights reserved.
//


import Foundation
import BaseFleksyApp


/// The type for the generic type `ContentType` in `BaseApp`.
public struct GifContent: BaseContent {
    public var id: String
    var gifURL: URL
    var thumbnailVideo: BaseMedia
    
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
