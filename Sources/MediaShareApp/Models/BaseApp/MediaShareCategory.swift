//  MediaShareCategory.swift
//  FleksyApps
//
//  Copyright © 2024 Thingthing. All rights reserved.
//

import Foundation
import BaseFleksyApp

/// The type for the generic type`Category` in `BaseApp`.
///
/// - Important: You need not use this type. This type is public only because it conforms to the `BaseCategory` protocol declared in the BaseApp.
public struct MediaShareCategory: BaseCategory {
    
    /// The user-facing name of the category.
    public let categoryName: String
    
    /// A unique identifier of the category content.
    public var id: String { query }
    
    /// The search query that the category triggers. An empty query triggers the "trending" category API call.
    let query: String
    
    enum CategoryType: Equatable, Hashable {
        case trending
        case tag(String)
    }
    
    init(name: String) {
        self.init(categoryName: name, query: name)
    }
    
    private init(categoryName: String, query: String) {
        self.categoryName = categoryName
        self.query = query
    }
    
    static let trendingCategory = MediaShareCategory(categoryName: MediaShareConstants.LocalizedStrings.trendingCategoryName, query: "")
}
