//  BaseConfiguration.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//

import Foundation
import FleksyAppsCore

/// The basic configuration of the `BaseApp`.
public struct BaseConfiguration {
    
    /// The placeholder text for the search text field in the FleksyApp.
    public let searchPlaceholder: String
    
    /// The text for the search button in `KeyboardAppViewMode.fullCover` mode
    public let searchButtonText: String
    
    /// The max count limit for the paginated requests of items.
    public let requestLimit: Int
    
    public let mediaRequestsTimeout: TimeInterval
    
    /// Initializes the `BaseConfiguration` object.
    /// - Parameters:
    ///   - searchPlaceholder: The placeholder text for the search text field in the FleksyApp. Defaults to ``BaseConstants/LocalizedStrings/search``.
    ///   - searchButtonText: The text for the search button in `KeyboardAppViewMode.fullCover` mode. Defaults to ``BaseConstants/LocalizedStrings/search``.
    ///   - requestLimit: The max count limit for the paginated requests of items. Defaults to 20 items.
    ///   - mediaRequestsTimeout: The timeout for the media network requests. Defaults to 60 seconds.
    public init(searchPlaceholder: String = BaseConstants.LocalizedStrings.search, searchButtonText: String = BaseConstants.LocalizedStrings.search, requestLimit: Int = 20, mediaRequestsTimeout: TimeInterval = 60) {
        self.searchPlaceholder = searchPlaceholder
        self.searchButtonText = searchButtonText
        self.requestLimit = requestLimit
        self.mediaRequestsTimeout = mediaRequestsTimeout
    }
}
