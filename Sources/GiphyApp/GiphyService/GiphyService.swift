//  GiphyService.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//

import Foundation
import BaseFleksyApp

/// The class that manages the Giphy requests and the download of the gifs to be shared by the user.
///
/// The ``GiphyApp`` uses this class to make the requests to the Giphy servers.
class GiphyService {
    
    typealias GifDataResult = Result<Data, BaseError>
    
    static let apiBaseURL = URL(string: "https://api.giphy.com")!
    
    /// For more ratings, see https://developers.giphy.com/docs/optional-settings/#rating
    static let defaultRating = "g" // "g" means Suitable for all audiences.
    
    static let defaultTimeout: TimeInterval = 60
        
    enum GifsCall {
        case search(query: String, limit: Int, offset: Int)
        case trending(limit: Int, offset: Int)
    }
    
    private static let validResponseCodes: Set<Int> = [200]
                                                               
    private let giphyApiKey: String
    
    var language: String?
    private var currentGifDataTask: Task<GifDataResult, Never>?
    
    // MARK: - Init
    
    init(giphyApiKey: String) {
        self.giphyApiKey = giphyApiKey
    }
    
    // MARK: - Interface methods
    
    func getGifs(_ gifsCall: GifsCall, timeout: TimeInterval = GiphyService.defaultTimeout) async -> Result<GifsResponse, BaseError> {
        let request = createGifsRequest(for: gifsCall, timeout: timeout)
        return await makeGiphyAPIRequest(request)
    }
    
    func getTrendingSearches(timeout: TimeInterval = GiphyService.defaultTimeout) async -> Result<TrendingSearchesResponse, BaseError> {
        let request = createTrendingSearchesRequest(timeout: timeout)
        return await makeGiphyAPIRequest(request)
    }
    
    func getGifData(from content: GifContent, timeout: TimeInterval = GiphyService.defaultTimeout) async -> GifDataResult {
        var request = URLRequest(url: content.gifURL)
        request.timeoutInterval = timeout
        return await makeGiphyGifRequest(request)
    }
    
    // MARK: - Private methods
    
    private func createGifsRequest(for gifsCall: GifsCall, timeout: TimeInterval) -> URLRequest {
        var urlComponents = URLComponents()
        var queryItems = [
            URLQueryItem(name: "api_key", value: giphyApiKey),
            URLQueryItem(name: "rating", value: Self.defaultRating),
        ]
        switch gifsCall {
        case .search(let query, let limit, let offset):
            urlComponents.path = "/v1/gifs/search"
            queryItems.append(URLQueryItem(name: "q", value: query))
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
            if let language {
                queryItems.append(URLQueryItem(name: "lang", value: language))
            }
        case .trending(let limit, let offset):
            urlComponents.path = "/v1/gifs/trending"
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url(relativeTo: Self.apiBaseURL) else {
            fatalError("Could not create url download Giphy gifs")
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        return request
    }
    
    private func createTrendingSearchesRequest(timeout: TimeInterval) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.path = "/v1/trending/searches"
        urlComponents.queryItems = [
            URLQueryItem(name: "api_key", value: giphyApiKey),
        ]
        
        guard let url = urlComponents.url(relativeTo: Self.apiBaseURL) else {
            fatalError("Could not create url download Giphy gifs")
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        return request
    }
    
    private func makeGiphyAPIRequest<T: Decodable>(_ request: URLRequest) async -> Result<T, BaseError> {
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
    
    private func makeGiphyGifRequest(_ request: URLRequest) async -> GifDataResult {
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
