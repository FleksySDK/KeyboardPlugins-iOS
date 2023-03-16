//  BaseCategory.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//


import Foundation

/// The type for the generic `ContentType` in `BaseApp`.
public protocol BaseCategory: Hashable {
    
    /// A unique identifier for the category.
    ///
    /// This identifier is used to differentiate between categories.
    var id: String { get }
    
    /// The name of the category. This string is shown to the user in the category selector.
    var categoryName: String { get }
}

/// This allows to easily hide the FleksyApp category selection view, in case it's not needed
extension Never: BaseCategory {
    public var id: String { "" }
    
    public var categoryName: String { "" }
}
