//  Pagination.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//  


import Foundation

/// An object that the ``BaseApp`` uses to communicate the required page for a request of the paginated service to obtain the contents for the FleksyApp.
public struct Pagination {
    
    /// The page to obtain (zero indexed).
    public var page: Int
    
    /// The position of the first element to return in the request (zero indexed).
    public var offset: Int
    
    /// The maximum number of elements to request in the request.
    public let limit: Int
    
    /// Convenienve property to check if it's the first page ( `page == 0`).
    public var isFirstPage: Bool { page == 0 }
    
    /// Initializes a new `Pagination` instance
    /// - Parameters:
    ///   - page: The page to obtain (zero indexed).
    ///   - offset: The position of the first element to return in the request (zero indexed).
    ///   - limit: The maximum number of elements to request in the request.
    public init(page: Int = 0, offset: Int = 0, limit: Int) {
        self.page = page
        self.offset = offset
        self.limit = limit
    }
    
    /// Returns the position of the last element to return in the request (zero indexed).
    public var lastIncludedOffset: Int {
        offset + limit - 1
    }
    
    /// Returns the pagination corresponding to the next request to the one represented by the receiver.
    ///
    /// For example, the following expression would evaluate to `true`:
    ///
    /// ```swift
    /// Pagination(page: 0, offset: 0, limit: 20).next()
    ///     == Pagination(page: 1, offset: 20, limit: 20)
    /// ```
    public func next() -> Pagination {
        return Pagination(page: page + 1,
                          offset: offset + limit,
                          limit: limit)
    }
}
