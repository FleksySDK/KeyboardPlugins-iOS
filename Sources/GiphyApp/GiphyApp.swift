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

final public class GiphyApp: BaseApp<GifContent, GifsCategory> {
    
    /// Animations constants
    private static let defaultToastDuration: UInt64 = 2 // Seconds
    private static let downloadingToastDelay: TimeInterval = 0.3 // Seconds
    
    /// The unique app identifier of the Giphy app.
    public static let appId = "com.fleksy.app.giphy"

    
    private let apiKey: String
    private lazy var service = GiphyService(giphyApiKey: apiKey)
    
    public init(apiKey: String) {
        let configuration = BaseConfiguration(searchPlaceholder: GiphyConstants.LocalizedStrings.searchPlaceHolder,
                                              searchButtonText: GiphyConstants.LocalizedStrings.searchButtonText)
        self.apiKey = apiKey
        super.init(id: Self.appId, configuration: configuration)
    }
    
    public override func appIcon() -> UIImage? {
        return GiphyConstants.giphyAppIcon
    }
    
    public override func initialize(listener: AppListener, configuration: AppConfiguration) {
        service.language = configuration.giphyLanguage
        super.initialize(listener: listener, configuration: configuration)
    }
    
    public override func onConfigurationChanged(_ configuration: AppConfiguration) {
        service.language = configuration.giphyLanguage
        super.onConfigurationChanged(configuration)
    }
    
    public override func getDefaultContentsFor(pagination: Pagination) async -> Result<[GifContent], BaseError> {
        await setSelectedCategory(GifsCategory.trendingCategory)
        return await service.getGifs(.trending(limit: pagination.limit, offset: pagination.offset)).map {
            $0.toResultsWithPoweredBy(pagination: pagination)
        }
    }
    
    public override func getContentsFor(category: GifsCategory, pagination: Pagination) async -> Result<[GifContent], BaseError> {
        if category.query.isEmpty {
            return await getDefaultContentsFor(pagination: pagination)
        } else {
            return await getContentsFor(query: category.query, pagination: pagination)
        }
    }
    
    public override func getContentsFor(query: String, pagination: Pagination) async -> Result<[GifContent], BaseError> {
        if query.isEmpty {
            return await getDefaultContentsFor(pagination: pagination)
        } else {
            return await getSearchResultsFor(nonEmptyQuery: query, pagination: pagination)
        }
    }
    
    public override func getCategories() async -> [GifsCategory] {
        let categories = try? await service.getTrendingSearches().map {
            $0.toCategories()
        }.get()
        return categories ?? []
    }
    
    private var currentContentSelectionTask: Task<Void, Never>?
    public override func didSelectContent(_ content: GifContent) {
        currentContentSelectionTask?.cancel()
        currentContentSelectionTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            // With the delay we avoid changing the toast message to the user too quickly.
            // If the gif download takes longer than 0.3 seconds, then the "downloading" message
            // is shown to provide quick feedback.
            await self.showToast(message: GiphyConstants.LocalizedStrings.toastDownloading, showLoader: true, delay: GiphyApp.downloadingToastDelay)
            let result = await self.service.getGifData(from: content)
            guard !Task.isCancelled else { return }
            
            switch result {
            case .success(let gifData):
                await self.copyGifDataToClipboard(gifData)
                await self.showToastAndWait(message: GiphyConstants.LocalizedStrings.toastCopiedAndReady)
                try? await Task.sleep(nanoseconds: GiphyApp.defaultToastDuration * NSEC_PER_SEC)
                guard !Task.isCancelled else { return }
                await self.hideToastAndWait()
                guard !Task.isCancelled else { return }
                await self.appListener?.hide()
            case .failure(let error):
                let message = GiphyConstants.LocalizedStrings.gifDownloadError + "\n" + error.defaultErrorMessage
                await self.showToastAndWait(message: message)
                try? await Task.sleep(nanoseconds: GiphyApp.defaultToastDuration * NSEC_PER_SEC)
                guard !Task.isCancelled else { return }
                await self.hideToastAndWait()
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
