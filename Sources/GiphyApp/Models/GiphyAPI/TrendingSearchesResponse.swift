//  CategoryResponse.swift
//  FleksyApps
// 
//  Copyright © 2023 Thingthing. All rights reserved.
//
    

import Foundation
import BaseFleksyApp

struct TrendingSearchesResponse: Decodable {
    let data: [String]
    let meta: GiphyMeta
}

// MARK: - Mapping TrendingSearchesResponse -> [GifsCategory]

extension TrendingSearchesResponse {
    
    func toCategories() -> [GifsCategory] {
        let categories = data.map {
            GifsCategory(name: $0)
        }
        return [GifsCategory.trendingCategory] + categories
    }
}
