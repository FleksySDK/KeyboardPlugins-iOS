//  GiphyApp.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//

import Foundation

struct GiphyMeta: Decodable {
    var status: Int
    var responseId: String
    var msg: String
}

struct GiphyPagination: Decodable {
    var totalCount: Int
    var count: Int
    var offset: Int
}
