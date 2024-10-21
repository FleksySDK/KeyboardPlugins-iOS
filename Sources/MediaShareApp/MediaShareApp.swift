//  MediaShareApp.swift
//  FleksyApps
//
//  Copyright © 2024 Thingthing. All rights reserved.
//

import UIKit
import BaseFleksyApp
import FleksyAppsCore
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// The main class of MediaShare FleksyApp.
///
/// Use this class as the entry point to add the MediaShare App to your keyboard extension.
final public class MediaShareApp: BaseApp<MediaShareContent, MediaShareCategory> {
    
    /// The types of content that the MediaShare app supports.
    public enum ContentType {
        
        /// Keyboard app for sharing clips. Requires using a FleksySDK license that includes the `fleksyapp_clips` capability.
        case clips
        
        /// Keyboard app for sharing gifs. Requires using a FleksySDK license that includes the `fleksyapp_gifs` capability.
        case gifs
        
        /// Keyboard app for sharing stickers. Requires using a FleksySDK license that includes the `fleksyapp_stickers` capability.
        case stickers
    }
    
    // Animations constants
    private static let defaultToastDuration: UInt64 = 2 // Seconds
    private static let downloadingToastDelay: TimeInterval = 0.3 // Seconds
    
    /// The unique app identifier of the MediaShare app.
    public static func appId(forContentType contentType: ContentType) -> String {
        let appIdSuffix =  switch contentType {
        case .clips: "clips"
        case .gifs: "gifs"
        case .stickers: "stickers"
        }
        return "com.fleksy.app.MediaShare." + appIdSuffix
    }
    
    private let contentType: ContentType
    private let service: MediaShareService
    
    public override var allowAudioInVideoPreviews: Bool {
        switch contentType {
        case .clips: true
        case .gifs: false
        case .stickers: false
        }
    }
    
    public override func initialize(listener: AppListener, configuration: AppConfiguration) {
        super.initialize(listener: listener, configuration: configuration)
        service.scheduleHealthCheckIfNeeded()
    }
    
    /// The icon for the MediaShare app.
    ///
    /// You need not call this method at any point. This method is public only for conformance to the `KeyboardApp` protocol declared in the package `FleksyAppsCore`.
    public override func appIcon() -> UIImage? {
        return MediaShareConstants.appIcon(for: contentType)
    }
    
    /// Creates a new instance of the MediaShareApp with the given MediaShare api key.
    /// - Parameters:
    ///   - contentType: The type of content for the user to pick in the MediaShare keyboard app.
    ///   - apiKey: The MediaShare api key.
    ///   - sdkLicenseKey: The license key for the FleksySDK.
    ///
    /// - Important:
    /// The license used (`sdkLicenseKey`) should contain the appropriate capability for the passed `contentType` (see ``ContentType``).
    public init(contentType: ContentType, apiKey: String, sdkLicenseKey: String) {
        let configuration = BaseConfiguration(searchPlaceholder: MediaShareConstants.LocalizedStrings.searchPlaceHolder.get(for: contentType),
                                              searchButtonText: MediaShareConstants.LocalizedStrings.searchButtonText.get(for: contentType))
        self.service = MediaShareService(contentType: contentType, MediaShareApiKey: apiKey, sdkLicenseId: sdkLicenseKey)
        self.contentType = contentType
        super.init(id: Self.appId(forContentType: contentType), configuration: configuration)
    }
    
    /// Gets the default content page for the app.
    /// - Important: **Do not call this method at any point**. This method is public only because it overrides the same method of the `BaseApp`.
    public override func getDefaultContentsFor(pagination: Pagination) async -> Result<[MediaShareContent], BaseError> {
        await setSelectedCategory(MediaShareCategory.trendingCategory(for: contentType))
        return await service.getContent(.trending(page: pagination.page + 1)).map {
            $0.toResults(contentType: contentType)
        }
    }
    
    public override func getContentsFor(category: MediaShareCategory, pagination: Pagination) async -> Result<[MediaShareContent], BaseError> {
        if category.query.isEmpty {
            return await getDefaultContentsFor(pagination: pagination)
        } else {
            return await getContentsFor(query: category.query, pagination: pagination)
        }
    }
    
    public override func getContentsFor(query: String, pagination: Pagination) async -> Result<[MediaShareContent], BaseError> {
        if query.isEmpty {
            return await getDefaultContentsFor(pagination: pagination)
        } else {
            return await getSearchResultsFor(nonEmptyQuery: query, pagination: pagination)
        }
    }
    
    public override func getCategories() async -> [MediaShareCategory] {
        let categories = try? await service.getTags().map {
            $0.toCategories(contentType: contentType)
        }.get()
        return categories ?? []
    }
    
    public override func getListViewConfiguration(forViewMode viewMode: KeyboardAppViewMode) -> ListViewConfiguration {
        var configuration = super.getListViewConfiguration(forViewMode: viewMode)
        configuration.bands = 1
        return configuration
    }
    
    private var currentContentSelectionTask: Task<Void, Never>?
    
    /// Performs the action after the user selects a given content in the app.
    /// - Important: **Do not call this method at any point**. This method is public only because it overrides the same method of the `BaseApp`.
    public override func didSelectContent(_ content: MediaShareContent) {
        service.sendImpresion(.share, for: content)
        currentContentSelectionTask?.cancel()
        currentContentSelectionTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            
            // With the delay we avoid changing the toast message to the user too quickly.
            // If the gif download takes longer than 0.3 seconds, then the "downloading" message
            // is shown to provide quick feedback.
            await self.showToast(message: MediaShareConstants.LocalizedStrings.toastDownloading.get(for: contentType), showLoader: true, delay: MediaShareApp.downloadingToastDelay)
            let result = await self.service.getContentData(from: content)
            guard !Task.isCancelled else { return }
            
            switch result {
            case .success(let gifData):
                await self.copyMediaDataToClipboard(gifData, content: content)
                await self.showToastAndWait(message: MediaShareConstants.LocalizedStrings.toastCopiedAndReady.get(for: contentType))
                try? await Task.sleep(nanoseconds: MediaShareApp.defaultToastDuration * NSEC_PER_SEC)
                guard !Task.isCancelled else { return }
                await self.hideToastAndWait()
                guard !Task.isCancelled else { return }
                await self.appListener?.hide()
            case .failure(let error):
                let message = MediaShareConstants.LocalizedStrings.contentDownloadError.get(for: contentType) + "\n" + error.defaultErrorMessage
                await self.showToastAndWait(message: message)
                try? await Task.sleep(nanoseconds: MediaShareApp.defaultToastDuration * NSEC_PER_SEC)
                guard !Task.isCancelled else { return }
                await self.hideToastAndWait()
            }
        }
    }
    
    public override func willShowContent(_ content: MediaShareContent) {
        service.sendImpresion(.view, for: content)
    }
    
    // MARK: - Private methods
    
    private func getSearchResultsFor(nonEmptyQuery query: String, pagination: Pagination) async -> Result<[MediaShareContent], BaseError> {
        let equivalentCategory = currentCategories.first(where: { $0.query.caseInsensitiveCompare(query) == .orderedSame })
        await setSelectedCategory(equivalentCategory)
        return await service.getContent(.search(query: query, page: pagination.page + 1)).map {
            $0.toResults(contentType: contentType)
        }
    }
    
    @MainActor
    private func copyMediaDataToClipboard(_ mediaData: Data, content: MediaShareContent) {
        var item: [String : Any] = [content.pasteboardType : mediaData]
        if let contentURL = content.contentURL {
            item[MediaShareConstants.urlPastboardType] = contentURL
        }
        UIPasteboard.general.items = [item]
    }
}
