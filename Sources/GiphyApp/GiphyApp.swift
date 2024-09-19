//  GiphyApp.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//

import UIKit
import BaseFleksyApp
import FleksyAppsCore
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// The main class of Giphy FleksyApp.
///
/// Use this class as the entry point to add the Giphy App to your keyboard extension.
@available(*, deprecated, message: "The GiphyApp has been deprecated and will be removed in the future. It has been replaced by the MediaShareApp from the same Swift Package, which, besides Gifs, also supports Clip videos and Stickers")
final public class GiphyApp: BaseApp<GifContent, GifsCategory> {
    
    // Animations constants
    private static let defaultToastDuration: UInt64 = 2 // Seconds
    private static let downloadingToastDelay: TimeInterval = 0.3 // Seconds
    
    /// The unique app identifier of the Giphy app.
    public static let appId = "com.fleksy.app.giphy"

    
    private let apiKey: String
    private lazy var service = GiphyService(giphyApiKey: apiKey)
    
    /// Creates a new instance of the GiphyApp with the given Giphy api key.
    /// - Parameter apiKey: The Giphy api key.
    public init(apiKey: String) {
        let configuration = BaseConfiguration(searchPlaceholder: GiphyConstants.LocalizedStrings.searchPlaceHolder,
                                              searchButtonText: GiphyConstants.LocalizedStrings.searchButtonText)
        self.apiKey = apiKey
        super.init(id: Self.appId, configuration: configuration)
    }
    
    /// The icon for the Giphy app.
    ///
    /// You need not call this method at any point. This method is public only for conformance to the `KeyboardApp` protocol declared in the package `FleksyAppsCore`.
    public override func appIcon() -> UIImage? {
        return GiphyConstants.giphyAppIcon
    }
    
    /// Applies the initial configuration to the app.
    /// - Important: **Do not call this method at any point**. This method is public only for conformance to the `KeyboardApp` protocol declared in the package `FleksyAppsCore`.
    public override func initialize(listener: AppListener, configuration: AppConfiguration) {
        service.language = configuration.giphyLanguage
        super.initialize(listener: listener, configuration: configuration)
    }
    
    /// Updates the configuration to the app.
    /// - Important: **Do not call this method at any point**. This method is public only for conformance to the `KeyboardApp` protocol declared in the package `FleksyAppsCore`.
    public override func onConfigurationChanged(_ configuration: AppConfiguration) {
        service.language = configuration.giphyLanguage
        super.onConfigurationChanged(configuration)
    }
    
    /// Gets the default content page for the app.
    /// - Important: **Do not call this method at any point**. This method is public only because it overrides the same method of the `BaseApp`.
    public override func getDefaultContentsFor(pagination: Pagination) async -> Result<[GifContent], BaseError> {
        await setSelectedCategory(GifsCategory.trendingCategory)
        return await service.getGifs(.trending(limit: pagination.limit, offset: pagination.offset)).map {
            $0.toResultsWithPoweredBy(pagination: pagination)
        }
    }
    
    /// Gets the content page for a given category for the app.
    /// - Important: **Do not call this method at any point**. This method is public only because it overrides the same method of the `BaseApp`.
    public override func getContentsFor(category: GifsCategory, pagination: Pagination) async -> Result<[GifContent], BaseError> {
        if category.query.isEmpty {
            return await getDefaultContentsFor(pagination: pagination)
        } else {
            return await getContentsFor(query: category.query, pagination: pagination)
        }
    }
    
    /// Gets the content page for a given query for the app.
    /// - Important: **Do not call this method at any point**. This method is public only because it overrides the same method of the `BaseApp`.
    public override func getContentsFor(query: String, pagination: Pagination) async -> Result<[GifContent], BaseError> {
        if query.isEmpty {
            return await getDefaultContentsFor(pagination: pagination)
        } else {
            return await getSearchResultsFor(nonEmptyQuery: query, pagination: pagination)
        }
    }
    
    /// Gets the available categories for the app.
    /// - Important: **Do not call this method at any point**. This method is public only because it overrides the same method of the `BaseApp`.
    public override func getCategories() async -> [GifsCategory] {
        let categories = try? await service.getTrendingSearches().map {
            $0.toCategories()
        }.get()
        return categories ?? []
    }
    
    private var currentContentSelectionTask: Task<Void, Never>?
    
    /// Performs the action after the user selects a given content in the app.
    /// - Important: **Do not call this method at any point**. This method is public only because it overrides the same method of the `BaseApp`.
    public override func didSelectContent(_ content: GifContent) {
        currentContentSelectionTask?.cancel()
        currentContentSelectionTask = Task.detached(priority: .userInitiated) { [weak self] in
            // With the delay we avoid changing the toast message to the user too quickly.
            // If the gif download takes longer than 0.3 seconds, then the "downloading" message
            // is shown to provide quick feedback.
            await self?.showToast(message: GiphyConstants.LocalizedStrings.toastDownloading, showLoader: true, delay: GiphyApp.downloadingToastDelay)
            guard let result = await self?.service.getGifData(from: content) else { return }
            guard !Task.isCancelled else { return }
            
            switch result {
            case .success(let gifData):
                await self?.copyGifDataToClipboard(gifData)
                await self?.showToastAndWait(message: GiphyConstants.LocalizedStrings.toastCopiedAndReady)
                try? await Task.sleep(nanoseconds: GiphyApp.defaultToastDuration * NSEC_PER_SEC)
                guard !Task.isCancelled else { return }
                await self?.hideToastAndWait()
                guard !Task.isCancelled else { return }
                await self?.appListener?.hide()
            case .failure(let error):
                let message = GiphyConstants.LocalizedStrings.gifDownloadError + "\n" + error.defaultErrorMessage
                await self?.showToastAndWait(message: message)
                try? await Task.sleep(nanoseconds: GiphyApp.defaultToastDuration * NSEC_PER_SEC)
                guard !Task.isCancelled else { return }
                await self?.hideToastAndWait()
            }
        }
    }
    
    // MARK: - Private methods
    
    private func getSearchResultsFor(nonEmptyQuery query: String, pagination: Pagination) async -> Result<[GifContent], BaseError> {
        let equivalentCategory = currentCategories.first(where: { $0.query.caseInsensitiveCompare(query) == .orderedSame })
        await setSelectedCategory(equivalentCategory)
        return await service.getGifs(.search(query: query, limit: pagination.limit, offset: pagination.offset)).map {
            $0.toResults()
        }
    }
    
    @MainActor
    private func copyGifDataToClipboard(_ gifData: Data) {
        let type: String
        if #available(iOS 14.0, *) {
#if canImport(UniformTypeIdentifiers)
            type = UTType.gif.identifier
#else
            type = "com.compuserve.gif"
#endif
        } else {
            type = "com.compuserve.gif"
        }
        UIPasteboard.general.setData(gifData, forPasteboardType: type)
    }
}

private extension AppConfiguration {
    
    /// Returns the language for the Giphy API based on the `AppConfiguration` locale.
    var giphyLanguage: String? {
        let locale: Locale
        if !currentLocale.isEmpty {
            locale = Locale(identifier: currentLocale)
        } else {
            locale = Locale.autoupdatingCurrent
        }
        
        let languageCode: String?
        if #available(iOS 16, *) {
            languageCode = locale.language.languageCode?.identifier
        } else {
            languageCode = locale.languageCode
        }
        return languageCode
    }
}
