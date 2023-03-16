//  Pagination.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//  


import Foundation

public struct Pagination {
    public var page: Int
    public var offset: Int
    public let limit: Int
    
    public var isFirstPage: Bool { page == 0 }
    
    public init(page: Int = 0, offset: Int = 0, limit: Int) {
        self.page = page
        self.offset = offset
        self.limit = limit
    }
    
    public var lastIncludedOffset: Int {
        offset + limit - 1
    }
    
    public func next() -> Pagination {
        return Pagination(page: page + 1,
                          offset: offset + limit,
                          limit: limit)
    }
}
