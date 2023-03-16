//  BaseMedia.swift
//  FleksyApps
// 
//  Copyright © 2023 Thingthing. All rights reserved.
//


import UIKit
import FleksyAppsCore

/// An object that contains media information.
///
/// The linked content by``BaseMedia/u``  will be shown in a cell of the list in the FleksyApp.
public struct BaseMedia: Equatable {
    
    /// The URL source.
    public let url: URL
    /// The extension of the file.
    public let fileExtension: String
    /// The media's width, in pixels.
    public let width: Int
    /// The media's height, in pixels.
    public let height: Int
    /// The media's content type.
    ///
    /// This type is used to decide what kind of cell is used in the collection view to present content.
    public let contentType: ContentType
    
    /// Creates a base media containing the source, lengths and type.
    ///
    /// Returns `nil` if `urlString` contains an invalid url.
    /// - Parameters:
    ///   - urlString: A `String` containing the URL source.
    ///   - width: The media's width, in pixels.
    ///   - height: The media's height, in pixels.
    ///   - contentType: The media's content type.
    public init?(urlString: String?, fileExtension: String, width: Int, height: Int, contentType: ContentType) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return nil
        }
        self.init(url: url, fileExtension: fileExtension, width: width, height: height, contentType: contentType)
    }
    
    /// Creates a base media containing the source, lengths and type.
    ///
    /// - Parameters:
    ///   - url: The URL source.
    ///   - width: The media's width, in pixels.
    ///   - height: The media's height, in pixels.
    ///   - contentType: The media's content type.
    public init(url: URL, fileExtension: String, width: Int, height: Int, contentType: ContentType) {
        self.url = url
        self.fileExtension = fileExtension
        self.width = width
        self.height = height
        self.contentType = contentType
    }
    
    /// Options for the supported media content type.
    public enum ContentType {
        case image
        case video
    }
}
