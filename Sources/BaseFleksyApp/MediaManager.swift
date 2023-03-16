//  MediaManager.swift
//  FleksyApps
//
//  Copyright © 2022 Thingthing. All rights reserved.
//

import Foundation

/// The object user by the ``BaseApp`` to manage the content download to be shown on the list.
actor MediaManager {
    
    private typealias MediaTask = Task<Result<URL, BaseError>, Never>
    
    private static let validResponseCodes = 200...204
    
    private var activeTasks: [String: MediaTask] = [:]
    
    private let mediaDirectory: URL
    private let timeout: TimeInterval
    
    init(appId: String, configuration: BaseConfiguration) {
        self.mediaDirectory = MediaManager.localMediaDirectory(for: appId)
        self.timeout = configuration.mediaRequestsTimeout
        
        if !FileManager.default.fileExists(atPath: mediaDirectory.path) {
            try? FileManager.default.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
        }
    }
    
    
    nonisolated func localFileURL(for result: any BaseContent) -> URL {
        getLocalURLForMedia(mediaId: result.id, fileExtension: result.viewMedia.fileExtension)
    }
    
    /// Downloads the speficied media.
    /// - Parameters:
    ///   - content: The `BaseContent` whose media to download.
    ///   - mediaId: The id of the media. This is used as the identifier for the final local url where the downloaded file gets saved.
    ///   - forceDownload: When `true`, download of the file is triggered even if a file for the given `mediaId` already exists locally.
    /// - Returns: a `Result` object containing the local url where the media has been saved in case of successful download.
    ///
    /// If the media already exists at the expected local url, it immediately returns the successful result containing the local url where the media is stored, without downloading it again.
    func downloadMediaIfNeeded(from content: any BaseContent, forceDownload: Bool = false) async -> Result<URL, BaseError> {
        let mediaId = content.id
        let localMediaURL = getLocalURLForMedia(mediaId: mediaId, fileExtension: content.viewMedia.fileExtension)
        
        if !forceDownload && FileManager.default.fileExists(atPath: localMediaURL.path) {
            // Local file already exists
            return .success(localMediaURL)
        }
        
        if let task = activeTasks[mediaId], !task.isCancelled {
            // Download task already happening; just wait
            return await task.value
        }
        
        // Trigger download
        let task = downloadTask(media: content.viewMedia, mediaId: mediaId, saveTo: localMediaURL)
        activeTasks[mediaId] = task
        
        return await task.value
    }
    
    func cancelMediaDownload(for result: any BaseContent) {
        activeTasks[result.id]?.cancel()
    }
    
    nonisolated private func getLocalURLForMedia(mediaId: String, fileExtension: String) -> URL {
        let baseURL: URL
        if #available(iOS 16.0, *) {
            baseURL = mediaDirectory.appending(path: mediaId, directoryHint: .notDirectory)
        } else {
            baseURL = mediaDirectory.appendingPathComponent(mediaId, isDirectory: false)
        }
        return baseURL.appendingPathExtension(fileExtension)
    }
    
    private func downloadTask(media: BaseMedia, mediaId: String, saveTo localMediaURL: URL) -> MediaTask {
        return MediaTask.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else {
                return .failure(.cancelled)
            }
            var request = URLRequest(url: media.url)
            request.timeoutInterval = self.timeout
            let result: Result<URL, BaseError>
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpStatus = response as? HTTPURLResponse {
                    if MediaManager.validResponseCodes ~= httpStatus.statusCode {
                        try data.write(to: localMediaURL, options: .atomic)
                        result = .success(localMediaURL)
                    } else {
                        result = .failure(.invalidHTTPStatusCode(httpStatus.statusCode))
                    }
                } else {
                    result = .failure(.other(nil))
                }
            } catch {
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .badServerResponse:
                        result = .failure(.badServerResponse)
                    case .badURL:
                        result = .failure(.badURL)
                    case .cancelled:
                        result = .failure(.cancelled)
                    case .notConnectedToInternet, .networkConnectionLost:
                        result = .failure(.noConnection)
                    case .timedOut:
                        result = .failure(.timeout)
                    default:
                        result = .failure(.other(urlError))
                    }
                } else {
                    result = .failure(.other(error))
                }
            }
            
            await self.removeActiveTaskFor(mediaId: mediaId)
            return result
        }
    }
    
    // MARK: - Private methods
    
    private func removeActiveTaskFor(mediaId: String) {
        activeTasks[mediaId] = nil
    }
    
    private static func localMediaDirectory(for appId: String) -> URL {
        // We use the cache directory for downloadable media
        let cacheDirectories = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheURL = cacheDirectories[0]
        if #available(iOS 16.0, *) {
            return cacheURL.appending(path: appId, directoryHint: .isDirectory)
        } else {
            return cacheURL.appendingPathComponent(appId, isDirectory: true)
        }
    }
}
