//  MediaShareService.swift
//  FleksyApps
//
//  Copyright © 2024 Thingthing. All rights reserved.
//

import Foundation
import BaseFleksyApp

/// The class that manages the MediaShare requests and the download of the media content to be shared by the user.
///
/// The ``MediaShareApp`` uses this class to make the requests to the servers.
class MediaShareService {
    
    typealias ContentDataResult = Result<Data, BaseError>
    
    static let apiURL = URL(string: "https://vvtzm33i71.execute-api.eu-west-1.amazonaws.com/Prod/api/v1/routing")!
        
    static let defaultTimeout: TimeInterval = 60
        
    enum Content {
        /// Trending content.
        /// - Parameter page: the requested page number. Minimum value 1.
        case trending(page: Int)
        
        /// Search content.
        /// - Parameter query: The search query for finding relevant content.
        /// - Parameter page: the requested page number. Minimum value 1.
        case search(query: String, page: Int)
    }
    
    private static let validResponseCodes: Set<Int> = [200]
                                    
    private let contentType: MediaShareRequestDTO.ContentType
    private let MediaShareApiKey: String
    private let sdkLicenseId: String
    
    private var currentGifDataTask: Task<ContentDataResult, Never>?
    
    // MARK: - Init
    
    init(contentType: MediaShareApp.ContentType, MediaShareApiKey: String, sdkLicenseId: String) {
        self.contentType = contentType.requestContent
        self.MediaShareApiKey = MediaShareApiKey
        self.sdkLicenseId = sdkLicenseId
    }
    
    // MARK: - Interface methods
    
    func getContent(_ content: Content, timeout: TimeInterval = MediaShareService.defaultTimeout) async -> Result<MediaShareResponse, BaseError> {
        let feature: MediaShareRequestDTO.Feature = switch content {
        case .trending(let page): .trending(page: page)
        case .search(let query, let page): .search(page: page, query: query)
        }
        
        let request = createContentRequest(for: feature, timeout: timeout)
        return await makeMediaShareAPIRequest(request)
    }
    
func getTags(timeout: TimeInterval = MediaShareService.defaultTimeout) async -> Result<PopularTagsResponse, BaseError> {
    let request = createContentRequest(for: .tags, timeout: timeout)
    return await makeMediaShareAPIRequest(request)
}
    
    func getContentData(from content: MediaShareContent, timeout: TimeInterval = MediaShareService.defaultTimeout) async -> ContentDataResult {
        guard let contentURL = content.contentURL else {
            return .failure(.badURL)
        }
        var request = URLRequest(url: contentURL)
        request.timeoutInterval = timeout
        return await makeMediaShareContentRequest(request)
    }
    
    // MARK: - Private methods
        
    private func createContentRequest(for feature: MediaShareRequestDTO.Feature, timeout: TimeInterval) -> URLRequest {
        let MediaShareRequestDTO = MediaShareRequestDTO(content: contentType, feature: feature)
        var request = URLRequest(url: Self.apiURL)
        
        request.httpMethod = "POST"
        
        request.timeoutInterval = timeout
        request.setValue(MediaShareApiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(contentType.requiredCapability, forHTTPHeaderField: "capability")
        request.setValue(sdkLicenseId, forHTTPHeaderField: "licenseId")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let jsonBody = try? JSONEncoder().encode(MediaShareRequestDTO)
        assert(jsonBody != nil, "Error when encoding MediaShareRequestDTO object")
        request.httpBody = jsonBody
        
        return request
    }
        
    private func makeMediaShareAPIRequest<T: Decodable>(_ request: URLRequest) async -> Result<T, BaseError> {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BaseError.other(nil)
            }
            guard Self.validResponseCodes.contains(httpResponse.statusCode) else {
                throw BaseError.invalidHTTPStatusCode(httpResponse.statusCode)
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedResponse = try decoder.decode(T.self, from: data)
            return .success(decodedResponse)
        } catch let baseError as BaseError {
            return .failure(baseError)
        } catch let urlError as URLError {
            switch urlError.code {
            case .badServerResponse:
                return .failure(.badServerResponse)
            case .badURL:
                return .failure(.badURL)
            case .cancelled:
                return .failure(.cancelled)
            case .notConnectedToInternet, .networkConnectionLost:
                return .failure(.noConnection)
            case .timedOut:
                return .failure(.timeout)
            default:
                return .failure(.other(urlError))
            }
        } catch {
            return .failure(.other(error))
        }
    }
    
    private func makeMediaShareContentRequest(_ request: URLRequest) async -> ContentDataResult {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BaseError.other(nil)
            }
            guard Self.validResponseCodes.contains(httpResponse.statusCode) else {
                throw BaseError.invalidHTTPStatusCode(httpResponse.statusCode)
            }
            return .success(data)
        } catch let baseError as BaseError {
            return .failure(baseError)
        } catch let urlError as URLError {
            switch urlError.code {
            case .badServerResponse:
                return .failure(.badServerResponse)
            case .badURL:
                return .failure(.badURL)
            case .cancelled:
                return .failure(.cancelled)
            case .notConnectedToInternet, .networkConnectionLost:
                return .failure(.noConnection)
            case .timedOut:
                return .failure(.timeout)
            default:
                return .failure(.other(urlError))
            }
        } catch {
            return .failure(.other(error))
        }
    }
}

fileprivate extension MediaShareApp.ContentType {
    
    var requestContent: MediaShareRequestDTO.ContentType {
        switch self {
        case .clips: return .clips
        case .gifs: return .gifs
        case .stickers: return .stickers
        }
    }
}

fileprivate extension MediaShareRequestDTO.ContentType {
    
    var requiredCapability: String {
        switch self {
        case .clips: return "fleksyapp_clips"
        case .gifs: return "fleksyapp_gifs"
        case .stickers: return "fleksyapp_stickers"
        }
    }
}
