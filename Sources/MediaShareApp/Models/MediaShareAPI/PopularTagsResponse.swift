//  PopularTagsResponse.swift
//  FleksyApps
//
//  Copyright © 2024 Thingthing. All rights reserved.
//
    

import Foundation
import BaseFleksyApp

struct PopularTagsResponse: Decodable {
    let tags: [String]?
}

// MARK: - Mapping PopularTagsResponse -> [MediaShareCategory]

extension PopularTagsResponse {
    
    func toCategories() -> [MediaShareCategory] {
        guard let tags, !tags.isEmpty else {
            return []
        }
        let categories = tags.map {
            MediaShareCategory(name: $0)
        }
        return [MediaShareCategory.trendingCategory] + (categories ?? [])
    }
}
