//  MediaShareRequestDTO.swift
//  FleksyApps
//
//  Copyright © 2024 Thingthing. All rights reserved.
//


import UIKit
import AdSupport

struct MediaShareRequestDTO: Encodable {
    
    enum ContentType: String, Encodable {
        case clips, gifs, stickers
    }
    
    enum Feature {
        case healthCheck
        
        case tags
        
        /// Trending content.
        /// - Parameter page: The requested page number. Minimum value 1.
        case trending(page: Int)
        
        /// Search content.
        /// - Parameter page: The requested page number. Minimum value 1.
        /// - Parameter query: The query String  for finding relevant content.
        case search(page: Int, query: String)
        
        /// Content displayed to the user.
        /// - Parameter contentId: The ID of the content displayed to the user.
        case viewTrigger(contentId: String)
        
        /// Content selected by the user for sharing.
        /// - Parameter contentId: The ID of the content selected by the user.
        case shareTrigger(contentId: String)
    }
    
    enum CodingKeys: String, CodingKey {
        case content
        case contentId
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
        case deviceOperatingSystemVersion
        case deviceHardwareVersion
        case deviceMake
        case deviceModel
        case deviceIfa
        case navigatorUserAgent = "userAgent"
    }
    
    let content: ContentType
    let feature: Feature
    let userId: String = (UIDevice.current.identifierForVendor ?? UUID()).uuidString
    let platform: String = UIDevice.current.systemName
    let adMinWidth: Int = 100
    let adMaxWidth: Int = 320
    let adMinHeight: Int = 100
    let adMaxHeight: Int = 250
    let deviceOperatingSystemVersion: String = UIDevice.current.systemVersion
    let deviceHardwareVersion: String = UIDevice.modelIdentifier
    let deviceMake: String = "apple"
    let deviceModel: String = UIDevice.current.model
    let deviceIdfa: String? = UIDevice.idfa
    let navigatorUserAgent: String
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(userId, forKey: .userId)
        try container.encode(platform, forKey: .platform)
        try container.encode(navigatorUserAgent, forKey: .navigatorUserAgent)
        
        let requiresAdsParameters: Bool
        
        switch feature {
        case .healthCheck:
            try container.encode("preFillAds", forKey: .feature)
            requiresAdsParameters = true
        case .tags:
            try container.encode("tags", forKey: .feature)
            requiresAdsParameters = false
        case .trending(let page):
            try container.encode("trending", forKey: .feature)
            try container.encode(page, forKey: .page)
            requiresAdsParameters = true
        case .search(let page, let query):
            try container.encode("search", forKey: .feature)
            try container.encode(query, forKey: .query)
            try container.encode(page, forKey: .page)
            requiresAdsParameters = true
        case .viewTrigger(let contentId):
            try container.encode("viewTrigger", forKey: .feature)
            try container.encode(contentId, forKey: .contentId)
            requiresAdsParameters = false
        case .shareTrigger(let contentId):
            try container.encode("shareTrigger", forKey: .feature)
            try container.encode(contentId, forKey: .contentId)
            requiresAdsParameters = false
        }
        
        if requiresAdsParameters {
            try container.encode(adMinWidth, forKey: .adMinWidth)
            try container.encode(adMaxWidth, forKey: .adMaxWidth)
            try container.encode(adMinHeight, forKey: .adMinHeight)
            try container.encode(adMaxHeight, forKey: .adMaxHeight)
        }
        
        try container.encode(deviceOperatingSystemVersion, forKey: .deviceOperatingSystemVersion)
        try container.encode(deviceHardwareVersion, forKey: .deviceHardwareVersion)
        try container.encode(deviceMake, forKey: .deviceMake)
        try container.encode(deviceModel, forKey: .deviceModel)
        try container.encode(deviceIdfa, forKey: .deviceIfa)
    }
}

private extension UIDevice {
    
    static let modelIdentifier: String = {
        let identifier: String
#if targetEnvironment(simulator)
        identifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]!
#else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
#endif
        return identifier
    }()
    
    private static let invalidIDFA = "00000000-0000-0000-0000-000000000000"
    
    static var idfa: String? {
        let idfaCandidate = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        guard idfaCandidate != invalidIDFA else {
            return nil
        }
        return idfaCandidate
    }
}
