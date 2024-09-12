//  MediaShareContent.swift
//  FleksyApps
//
//  Copyright © 2024 Thingthing. All rights reserved.
//

import Foundation
import BaseFleksyApp


/// The type for the generic type `ContentType` in `BaseApp`.
///
/// - Important: You need not use this type. This type is public only because it conforms to the `BaseContent` protocol declared in the `BaseApp`.
public struct MediaShareContent: BaseContent {
    
    /// A unique identifier of the gif content.
    public var id: String
    var contentURL: URL?
    var pasteboardType: String
    
    /// The content to be shown to the user.
    public var contentType: BaseContentType
}
