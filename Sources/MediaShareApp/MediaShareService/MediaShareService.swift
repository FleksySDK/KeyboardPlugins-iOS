//  MediaShareService.swift
//  FleksyApps
//
//  Copyright © 2024 Thingthing. All rights reserved.
//

import Foundation
import BaseFleksyApp
import WebKit

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
    
    enum ImpressionType {
        case view
        case share
    }
    
    private static let validResponseCodes: Set<Int> = [200]
                                    
    private let contentType: MediaShareRequestDTO.ContentType
    private let MediaShareApiKey: String
    private let sdkLicenseId: String
    
    private static let healthCheckMinWaitTime: TimeInterval = 600 // 10 minutes
    
    @MainActor private static var userAgentTask: Task<String, Never>?
    @MainActor private static var healthCheckTask: Task<(SimpleResultResponse, Date), Error>?
        
    // MARK: - Init
    
    init(contentType: MediaShareApp.ContentType, MediaShareApiKey: String, sdkLicenseId: String) {
        self.contentType = contentType.requestContent
        self.MediaShareApiKey = MediaShareApiKey
        self.sdkLicenseId = sdkLicenseId
    }
    
    // MARK: - Interface methods
    
    func scheduleHealthCheckIfNeeded() {
        Task {
            let initialDelay: UInt64 = 10_000_000_000
            try await Task.sleep(nanoseconds: initialDelay)
            await performHealthCheckRequestIfNeeded()
        }
    }
    
    func getContent(_ content: Content, timeout: TimeInterval = MediaShareService.defaultTimeout) async -> Result<MediaShareResponse, BaseError> {
        await performHealthCheckRequestIfNeeded(timeout: timeout)
        
        let feature: MediaShareRequestDTO.Feature = switch content {
        case .trending(let page): .trending(page: page)
        case .search(let query, let page): .search(page: page, query: query)
        }
        
        let navigatorUserAgent = await Self.retrieveNavigatorUserAgent()
        let request = createContentRequest(for: feature, navigatorUserAgent: navigatorUserAgent, timeout: timeout)
        return await makeMediaShareAPIRequest(request)
    }
    
    func getTags(timeout: TimeInterval = MediaShareService.defaultTimeout) async -> Result<PopularTagsResponse, BaseError> {
        await performHealthCheckRequestIfNeeded(timeout: timeout)
        let navigatorUserAgent = await Self.retrieveNavigatorUserAgent()
        let request = createContentRequest(for: .tags, navigatorUserAgent: navigatorUserAgent, timeout: timeout)
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
    
    func sendImpresion(_ type: ImpressionType, for content: MediaShareContent, timeout: TimeInterval = MediaShareService.defaultTimeout) {
        Task(priority: .background) {
            let feature: MediaShareRequestDTO.Feature = switch type {
            case .view: .viewTrigger(contentId: content.id)
            case .share: .shareTrigger(contentId: content.id)
            }
            
            let navigatorUserAgent = await Self.retrieveNavigatorUserAgent()
            let request = createContentRequest(for: feature, navigatorUserAgent: navigatorUserAgent, timeout: timeout)
            let _: Result<SimpleResultResponse, BaseError> = await makeMediaShareAPIRequest(request)
            return
        }
    }
    
    // MARK: - Private methods
    
    @MainActor private static func retrieveNavigatorUserAgent() async -> String {
        if let userAgentTask {
            return await userAgentTask.get()
        } else {
            let userAgentTask = Task {
                let webView = WKWebView()
                do {
                    let result = try await webView.evaluateJavaScript("navigator.userAgent")
                    if let navigatorUserAgent = result as? String {
                        return navigatorUserAgent
                    } else {
                        return ""
                    }
                } catch {
                    print("Error when retrieving navigator.userAgent: \(error)")
                    return ""
                }
            }
            self.userAgentTask = userAgentTask
            return await userAgentTask.get()
        }
    }

    @MainActor private func performHealthCheckRequestIfNeeded(timeout: TimeInterval = MediaShareService.defaultTimeout) async  {
        if let healthCheckTask = Self.healthCheckTask,
           let result = try? await healthCheckTask.result.get(),
           result.1.distance(to: Date()) < Self.healthCheckMinWaitTime
        {
            // Too soon to make a new health check request
            return
        }
        await performHealthCheckRequest(timeout: timeout)
    }
    
    @MainActor private func performHealthCheckRequest(timeout: TimeInterval) async {
        Self.healthCheckTask = Task {
            let navigatorUserAgent = await Self.retrieveNavigatorUserAgent()
            let request = createContentRequest(for: .healthCheck, navigatorUserAgent: navigatorUserAgent, timeout: timeout)
            let result: Result<SimpleResultResponse, BaseError> = await makeMediaShareAPIRequest(request)
            return (try result.get(), Date())
        }
        _ = await Self.healthCheckTask?.result
    }
    
    private func createContentRequest(for feature: MediaShareRequestDTO.Feature, navigatorUserAgent: String, timeout: TimeInterval) -> URLRequest {
        let mediaShareRequestDTO = MediaShareRequestDTO(content: contentType, feature: feature, navigatorUserAgent: navigatorUserAgent)
        var request = URLRequest(url: Self.apiURL)
        
        request.httpMethod = "POST"
        
        request.timeoutInterval = timeout
        request.setValue(MediaShareApiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(contentType.requiredCapability, forHTTPHeaderField: "capability")
        request.setValue(sdkLicenseId, forHTTPHeaderField: "licenseId")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let jsonBody = try? JSONEncoder().encode(mediaShareRequestDTO)
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
