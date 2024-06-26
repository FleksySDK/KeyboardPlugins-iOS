//  RemoteMedia.swift
//  FleksyApps
// 
//  Copyright © 2023 Thingthing. All rights reserved.
//


import UIKit
import FleksyAppsCore

/// An object that contains media information.
///
/// The linked content by``RemoteMedia/url``  will be shown in a cell of the list in the FleksyApp. The type of the cell will be determined by the ``RemoteMedia/contentType-swift.property``.
public struct RemoteMedia: Equatable {
    
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
    public let mediaType: MediaType
    
    /// Creates a remote media containing the source, lengths and type.
    ///
    /// Returns `nil` if `urlString` contains an invalid url.
    /// - Parameters:
    ///   - urlString: A `String` containing the URL source.
    ///   - fileExtension: The extension of the file.
    ///   - width: The media's width, in pixels.
    ///   - height: The media's height, in pixels.
    ///   - mediaType: The media's content type.
    public init?(urlString: String?, fileExtension: String, width: Int, height: Int, mediaType: MediaType) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return nil
        }
        self.init(url: url, fileExtension: fileExtension, width: width, height: height, mediaType: mediaType)
    }
    
    /// Creates a remote media containing the source, lengths and type.
    ///
    /// - Parameters:
    ///   - url: The URL source.
    ///   - width: The media's width, in pixels.
    ///   - height: The media's height, in pixels.
    ///   - mediaType: The media's content type.
    public init(url: URL, fileExtension: String, width: Int, height: Int, mediaType: MediaType) {
        self.url = url
        self.fileExtension = fileExtension
        self.width = width
        self.height = height
        self.mediaType = mediaType
    }
    
    /// Options for the supported media content type.
    ///
    /// This enum is used to decide the type of the cells shown in the media content carousel.
    public enum MediaType {
        
        /// The type of the content for static images.
        case image
        
        /// The type of the content for videos that are automatically played and muted.
        case video
    }
}
