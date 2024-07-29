//  MediaShareRequestDTO.swift
//  FleksyApps
//
//  Copyright © 2024 Thingthing. All rights reserved.
//


import UIKit

struct MediaShareRequestDTO: Encodable {
    
    enum ContentType: String, Encodable {
        case clips, gifs, stickers
    }
    
    enum Feature {
        case healthCheck
        
        case tags
        
        /// Trending content.
        /// - Parameter page: the requested page number. Minimum value 1.
        case trending(page: Int)
        
        /// Search content.
        /// - Parameter page: the requested page number. Minimum value 1.
        /// - Parameter query: The query String  for finding relevant content.
        case search(page: Int, query: String)
    }
    
    enum CodingKeys: String, CodingKey {
        case content
        case feature
        case userId
        case platform
        case query = "keyword"
        case tags
        case page
        
        case adMinWidth
        case adMaxWidth
        case adMinHeight
        case adMaxHeight
    }
    
    let content: ContentType
    let feature: Feature
    let userId: String = (UIDevice.current.identifierForVendor ?? UUID()).uuidString
    let platform: String = "ios"
    let adMinWidth: Int = 100
    let adMaxWidth: Int = 320
    let adMinHeight: Int = 100
    let adMaxHeight: Int = 250
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(userId, forKey: .userId)
        try container.encode(platform, forKey: .platform)
        try container.encode(adMinWidth, forKey: .adMinWidth)
        try container.encode(adMaxWidth, forKey: .adMaxWidth)
        try container.encode(adMinHeight, forKey: .adMinHeight)
        try container.encode(adMaxHeight, forKey: .adMaxHeight)
        
        switch feature {
        case .healthCheck:
            try container.encode("preFillAds", forKey: .feature)
        case .tags:
            try container.encode("tags", forKey: .feature)
        case .trending(let page):
            try container.encode("trending", forKey: .feature)
            try container.encode(page, forKey: .page)
        case .search(let page, let query):
            try container.encode("search", forKey: .feature)
            try container.encode(query, forKey: .query)
            try container.encode(page, forKey: .page)
        }
    }
}
