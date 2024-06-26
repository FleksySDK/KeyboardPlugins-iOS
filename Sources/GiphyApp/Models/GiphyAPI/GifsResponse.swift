//  GifsResponse.swift
//  FleksyApps
// 
//  Copyright © 2022 Thingthing. All rights reserved.
//
    

import Foundation
import BaseFleksyApp

struct GifsResponse: Decodable {
    let data: [GiphyGif]
    let pagination: GiphyPagination
    let meta: GiphyMeta
    
    struct GiphyGif: Decodable {
        let type: String
        let id: String
        let title: String
        let url: String
        let rating: String
        let images: Images
        
        struct Images: Decodable {
            let original: Image
            let fixedHeightSmall: Image
            
            struct Image: Decodable {
                let width: String?
                let height: String?
                let url: String?
                let mp4: String?
            }
        }
    }
}


// MARK: - Mapping GifsResponse -> [GifContent]

extension GifsResponse {
    
    func toResultsWithPoweredBy(pagination: Pagination) -> [GifContent] {
        if pagination.isFirstPage, let poweredByGiphyGif = GifContent.poweredByGiphyGif {
            return [poweredByGiphyGif] + toResults()
        } else {
            return toResults()
        }
    }
    
    func toResults() -> [GifContent] {
        data.compactMap {
            $0.toGifContent()
        }
    }
}

private extension GifsResponse.GiphyGif {
    
    func toGifContent() -> GifContent? {
        let thumbnail = images.fixedHeightSmall
        guard
            let gifURLString = images.original.url,
            let gifURL = URL(string: gifURLString),
            let width = thumbnail.width, let widthInt = Int(width),
            let height = thumbnail.height, let heightInt = Int(height),
            let thumbnailVideo = RemoteMedia(urlString: thumbnail.mp4,
                                             fileExtension: GiphyConstants.mp4MediaExtension,
                                             width: widthInt,
                                             height: heightInt,
                                             mediaType: .video)
        else {
            return nil
        }
        
        return GifContent(id: id, gifURL: gifURL, thumbnailVideo: thumbnailVideo)
    }
}
