//  MediaShareResponse.swift
//  FleksyApps
//
//  Copyright © 2024 Thingthing. All rights reserved.
//


import Foundation
import BaseFleksyApp

struct MediaShareResponse: Decodable {
    let contents: [Content]
    let advertisements: [Advertisement]
    let page: Int
    let hasNext: Bool
    
    struct Content: Decodable {
        let id: String
        let title: String
        let file: FileFormats
        
        struct FileFormats: Decodable {
            let gif: MediaItem?
            let webp: MediaItem?
            let mp4: MediaItem?
            
            struct MediaItem: Decodable {
                let `default`: File?
                let hd: File?
                let md: File?
                let sm: File?
                let xs: File?
                
                struct File: Decodable {
                    let url: String
                    let width: Int
                    let height: Int
                    let size: Int?
                }
                
                var fileForFinalContent: File? {
                    hd ?? md ?? sm ?? xs ?? self.default
                }
                
                var fileForThumbnailContent: File? {
                    sm ?? md ?? xs ?? hd ?? self.default
                }
            }
            
            var videoItemWithExtension: (item: MediaItem, extension: String)? {
                if let mp4 {
                    return (mp4, MediaShareConstants.mp4MediaExtension)
                } else if let webp {
                    return (webp, MediaShareConstants.webpMediaExtension)
                } else {
                    return nil
                }
            }
        }
    }
    
    struct Advertisement: Decodable {
        /// Text in HTML format
        let content: String
        
        let width: Int
        let height: Int
    }
}

// MARK: - Mapping MediaShareResponse -> [MediaShareContent]

extension MediaShareResponse {

    func toResults(contentType: MediaShareApp.ContentType) -> [MediaShareContent] {
        // Ads insert logic:
        // First ad item is randomly inserted in position 0, 1 or 2.
        // Each subsequent ad item is inserted randomly spaced by 1, 2 or 3 content items
                
        var results = contents.compactMap {
            $0.toMediaShareContent(contentType: contentType)
        }
                
        var nextAdIndex: Int = Int.random(in: 0...2)
        for advertisement in self.advertisements {
            let adContent = advertisement.toMediaShareContent()
            if nextAdIndex < results.endIndex {
                results.insert(adContent, at: nextAdIndex)
                nextAdIndex += Int.random(in: 2...4)
            } else {
                results.append(adContent)
                // No more contents -> do not add more ads
                break
            }
        }
        
        return results
    }
}

private extension MediaShareResponse.Advertisement {
    
    func toMediaShareContent() -> MediaShareContent {
        MediaShareContent(id: UUID().uuidString, pasteboardType: "", contentType: .html(content, width: width, height: height))
    }
}


private extension MediaShareResponse.Content {
    
    func toMediaShareContent(contentType: MediaShareApp.ContentType) -> MediaShareContent? {
        guard let (mediaItem, pasteboardType) = file.mediaItemWithPasteboardTypeForSharingContent(of: contentType),
              let shareFile = mediaItem.fileForFinalContent,
              let shareFileURL = URL(string: shareFile.url),
              let videoItemWithExtension = file.videoItemWithExtension,
              let thumbnailFile = videoItemWithExtension.item.fileForThumbnailContent
        else {
            return nil
        }
        let mediaType: RemoteMedia.MediaType = switch videoItemWithExtension.extension {
        case MediaShareConstants.mp4MediaExtension: .video
        case MediaShareConstants.webpMediaExtension: .image
        default: .image
        }
        
        let userFacingTitle: String? = switch contentType {
        case .clips: title
        case .gifs, .stickers: nil
        }
        
        guard let thumbnailMedia = RemoteMedia(title: userFacingTitle,
                                               urlString: thumbnailFile.url,
                                               fileExtension: videoItemWithExtension.extension,
                                               width: thumbnailFile.width,
                                               height: thumbnailFile.height,
                                               mediaType: mediaType)
        else {
            return nil
        }
        return MediaShareContent(id: id, contentURL: shareFileURL, pasteboardType: pasteboardType, contentType: .remoteMedia(thumbnailMedia))
    }
}

private extension MediaShareResponse.Content.FileFormats {
    
    func mediaItemWithPasteboardTypeForSharingContent(of contentType: MediaShareApp.ContentType) -> (MediaItem, String)? {
        switch contentType {
        case .clips:
            return getMp4WithPasteboardType() ?? getWebpWithPasteboardType() ?? getGifWithPasteboardType()
        case .gifs:
            return getGifWithPasteboardType() ?? getWebpWithPasteboardType() ?? getMp4WithPasteboardType()
        case .stickers:
            return getMp4WithPasteboardType() ?? getWebpWithPasteboardType() ?? getGifWithPasteboardType()
        }
    }
    
    private func getMp4WithPasteboardType() -> (MediaItem, String)? {
        mp4.map {
            ($0, MediaShareConstants.mp4PasteboardType)
        }
    }
    
    private func getWebpWithPasteboardType() -> (MediaItem, String)? {
        webp.map {
            ($0, MediaShareConstants.webpPasteboardType)
        }
    }
    
    private func getGifWithPasteboardType() -> (MediaItem, String)? {
        gif.map {
            ($0, MediaShareConstants.gifPasteboardType)
        }
    }
}
