//  GifsCategory.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//

import Foundation
import BaseFleksyApp

/// The type for the generic type`Category` in `BaseApp`.
///
/// - Important: You need not use this type. This type is public only because it conforms to the `BaseCategory` protocol declared in the BaseApp.
@available(*, deprecated, message: "The GiphyApp has been deprecated and will be removed in the future. It has been replaced by the MediaShareApp from the same Swift Package, which, besides Gifs, also supports Clip videos and Stickers")
public struct GifsCategory: BaseCategory {
    
    /// The user-facing name of the category.
    public let categoryName: String
    
    /// A unique identifier of the category content.
    public var id: String { query }
    
    /// The search query that the category triggers. An empty query triggers the "trending" Giphy API call.
    let query: String
    
    init(name: String) {
        self.init(categoryName: name, query: name)
    }
    
    private init(categoryName: String, query: String) {
        self.categoryName = categoryName
        self.query = query
    }
    
    static let trendingCategory = GifsCategory(categoryName: GiphyConstants.LocalizedStrings.trendingCategoryName, query: "")
}
