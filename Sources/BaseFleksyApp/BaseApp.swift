//  BaseApp.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//


import UIKit
import FleksyAppsCore
import SwiftUI
import AVKit

/// An object that handles the processes of a FleksyApp.
///
/// If the category selection view is not needed, you can use `Never` as the `Category` type in your subclass of ``BaseFleksyApp/BaseApp``.
/// - Important: This class is only meant to be subclassed. Do not use this class as is.
open class BaseApp<ContentType: BaseContent, Category: BaseCategory>: KeyboardApp {
    
    public typealias BaseContentResult = Result<[ContentType], BaseError>
    private typealias BaseContentTask = Task<BaseContentResult, Never>
    
    /// The unique app id.
    public let appId: String
    
    /// The last requested pagination or the pagination being requested currently
    /// if `activeContentsTask` is not nil and not cancelled.
    private var pagination: Pagination?
    
    /// The app configuration.
    public let configuration: BaseConfiguration
    
    /// The current contents being shown by the app.
    @MainActor
    public private(set) var currentContents: [ContentType] = [] {
        didSet {
            appView?.reloadContents(currentContents)
        }
    }
    
    /// The current available categories selectable by the user.
    public private(set) var currentCategories: [Category] = []
    private var selectedCategory: Category? {
        appView?.selectedCategoryIndex.map {
            currentCategories[$0]
        }
    }
    
    /// The Keyboard app may need to modify the audio session category for video playback.
    ///
    /// This closure is used to restore the audio session to its original state when the keyboard app closes.
    fileprivate var restoreAudioSessionCallback: (() -> Void)?
    
    private lazy var mediaManager = MediaManager(appId: appId, configuration: configuration)
    
    /// The function to load subsequent pages of the current
    private var currentContentsLoader: ((Pagination) async -> BaseContentResult)?
    
    /// The default category for the initial results load. By default, the ``BaseApp`` uses the first elements in ``BaseApp/currentCategories`` as the default category.
    ///
    /// Optionally override this property to return the desired category.
    open var defaultCategory: Category? {
        currentCategories.first
    }
    
    /// Whether the keyboard app should include the toggle for the user to enable audio in video previews. Detaults to `true`.
    open var allowAudioInVideoPreviews: Bool { true }
    
    /// The current `AppListener`.
    ///
    /// Subclasses of the ``BaseApp`` should use this object to show or hide.
    public internal(set) var appListener: AppListener?
    
    private var appView: BaseAppView<ContentType, Category>?
    
    /// Initialises and returns a newly allocated base app object with the specified ID.
    /// - Parameters:
    ///   - id: The unique app id.
    ///   - configuration: The configuration of the app to initialize. See ``BaseConfiguration/init(searchPlaceholder:searchButtonText:requestLimit:mediaRequestsTimeout:)`` for the default configuration.
    public init(id: String, configuration: BaseConfiguration = BaseConfiguration()) {
        self.appId = id
        self.configuration = configuration
    }
    
    // MARK: - KeyboardApp protocol
    
    /// Invoked when the app is registered.
    ///
    /// Default implementation sets the FleksyApp listener.
    /// - Parameters:
    ///   - listener: The listener that allows interaction with the SDK to perform actions on the keyboard.
    ///   - configuration: The locale configuration shared between all FleksyApps.
    ///
    /// Usually, you don't need to override this method, since the ``BaseApp`` already keeps a reference to the `listener` and applies the `configuration` to the app's view.
    ///
    /// - Important: If you need to override this method, always call `super`'s implementation at some point.
    open func initialize(listener: AppListener, configuration: AppConfiguration) {
        self.appListener = listener
    }
    
    /// Invoked when the app is being disposed, meaning, the app is not between the enabled apps in the keyboard anymore (i.e. the app was not added to the `KeyboardConfiguration`'s `AppsConfiguration`).
    ///
    /// Optionally override this method to release retained properties by the app and free resources until (if) initialize is called again.
    ///
    /// - Important: Always call `super`'s implementation.
    open func dispose() {
        appListener = nil
    }
    
    /// The view mode for the FleksyApp when opened from the carousel. The ``BaseApp`` returns `KeyboardAppViewMode.fullCover`
    ///
    /// Override this property if your FleksyApp needs a different initial view mode.
    open var defaultViewMode: KeyboardAppViewMode { .fullCover() }
    
    /// Invoked when the app is about to be opened. Returns the view to use for the FleksyApp.
    ///
    /// - Parameters:
    ///   - viewMode: The view mode the FleksyApp will use.
    ///   - theme: The theme the FleksyApp will use.
    /// - Returns: The current view the FleksyApp will present.
    ///
    /// - Important: If you need to override this method, always return `super`'s returned view.
    @MainActor
    open func open(viewMode: KeyboardAppViewMode, theme: AppTheme) -> UIView? {
        let view: BaseAppView<ContentType, Category>
        if let appView {
            appView.appTheme = theme
            appView.updateForViewMode(viewMode)
            view = appView
        } else {
            view = BaseAppView(viewMode: viewMode, appTheme: theme, delegate: self, searchText: configuration.searchButtonText)
            appView = view
        }

        if currentCategories.isEmpty {
            performInitialLoads()
        } else if currentContents.isEmpty {
            performDefaultRequest()
        }
        
        return view
    }
    
    /// Invoked when the app was just closed.
    ///
    /// The default implementation cleans up the allocated objects to release memory.
    ///
    /// - Important: Always call `super`'s implementation if overriding this method.
    @MainActor
    open func close() {
        appView = nil
        currentContentsLoader = nil
        activeContentsTask?.cancel()
        activeContentsTask = nil
        activeCategoriesTask?.cancel()
        activeCategoriesTask = nil
        currentContents = []
        currentCategories = []
        restoreAudioSessionCallback?()
    }
    
    /// Invoked when the configuration changed.
    ///
    /// - Parameter configuration: The new `AppConfiguration`.
    ///
    /// - Important: Always call `super`'s implementation if overriding this method (in case a future version of the ``BaseApp`` adds an implementation to this method).
    open func onConfigurationChanged(_ configuration: AppConfiguration) {}
    
    /// Invoked when the theme changes. Used by the ``BaseApp`` to update the theme on the app's view.
    ///
    /// - Parameter theme: The new theme.
    ///
    /// - Important: Always call `super`'s implementation if overriding this method.
    open func onThemeChanged(_ theme: AppTheme) {
        appView?.appTheme = theme
    }
    
    /// Returns icon of the app.
    ///
    /// Subclasses should override this method to customize their app icon. If you want the icon to adjust automaticaly to the current theme, consider using the `.alwaysTemplate` rendering mode.
    ///
    /// By default, the ``BaseApp`` returns a question mark icon.
    /// - Returns: The icon of the app.
    open func appIcon() -> UIImage? {
        return BaseConstants.Images.defaultAppIcon
    }
    
    // MARK: - Public interface
    
    // MARK: To override by subclasses
    
    /// Override this method to request and return the default list of contents to be shown when no query or category are selected.
    /// - Parameter pagination: The expected pagination for the request.
    /// - Returns: The result of the request.
    ///
    /// **This method must be overriden**. Do not call super's implementation, as it always returns an error.
    /// - Important: If the load of default contents is equivalent to getting the contents for a specific category,
    /// you need to manually call ``BaseApp/setSelectedCategory(_:)`` to visually mark that category as the selected one.
    open func getDefaultContentsFor(pagination: Pagination) async -> BaseContentResult {
        assertionFailure("Method \(#function) must be implemented by the BaseApp subclass")
        return .failure(.other(nil))
    }
    
    /// Override this method to request and return the results for a given category.
    /// - Parameters:
    ///   - category: The category selected by the user.
    ///   - pagination: The expected pagination for the request.
    /// - Returns: The result of the request.
    ///
    /// **This method must be overriden**. Do not call `super`'s implementation, as it always returns an error.
    ///
    /// When this method gets called, this means that the user selected the specific `category`, so you don't need to call
    /// ``BaseApp/setSelectedCategory(_:)`` since it is done automatically for you by the ``BaseApp`` implementation.
    open func getContentsFor(category: Category, pagination: Pagination) async -> BaseContentResult {
        assertionFailure("Method \(#function) must be implemented by the BaseApp subclass")
        return .failure(.other(nil))
    }
    
    /// Override this method to request and return the results for a given query.
    /// - Parameters:
    ///   - query: The query entered by the user.
    ///   - pagination: The expected pagination for the request.
    /// - Returns: The result of the request.
    ///
    /// **This method must be overriden**. Do not call `super`'s implementation, as it always returns an error.
    ///
    /// When this method gets called, this means that the user typed and searched for a specific query. If getting the contents for a
    /// specific query is equivalent to getting the contents for a specific category, you need to manually call
    /// ``BaseApp/setSelectedCategory(_:)`` to visually mark that category as the selected one.
    open func getContentsFor(query: String, pagination: Pagination) async -> BaseContentResult {
        assertionFailure("Method \(#function) must be implemented by the BaseApp subclass")
        return .failure(.other(nil))
    }
    
    /// Override this method to request and return the categories for app.
    /// - Returns: The categories available for the user to select. Returning an empty array hides the category selection view.
    ///
    /// **This method must be overriden** unless the `Category` type is `Never`. Do not call `super`'s implementation, as it always returns an empty array.
    open func getCategories() async -> [Category] {
        if Category.self != Never.self {
            assertionFailure("Method \(#function) must be implemented by the BaseApp subclass when using a custom `Category` type")
        }
        return []
    }
    
    
    /// Override this method to perform any desired action when the user taps a content cell.
    /// - Parameter content: The content object tapped by the user.
    ///
    /// The default implementation of this method does nothing. So you don't need to call `super`'s implementation
    @MainActor
    open func didSelectContent(_ content: ContentType) {}
    
    /// This method is called by the KeyboardSDK when the user taps the app icon next to the in-keyboard text field (during `TopBarMode.appTextField` mode). The implementation of the ``BaseApp`` transitions the FleksyApp to `KeyboardAppViewMode.fullCover` mode.
    ///
    /// Optionally override this method if your ``BaseApp`` subclass needs to implement its custom behavior.
    @MainActor
    open func onAppIconAction() {
        appListener?.show(mode: .fullCover())
    }
    
    /// Optionally override this method to return a custom error message for the FleksyApp based on the error.
    /// - Parameter error: The error that happened.
    /// - Returns: An error message to be presented to the user.
    ///
    /// The default implementation returns the `error`'s default error message (see ``BaseError/defaultErrorMessage``).
    ///
    /// To customize the error messages, you have two options:
    /// * Override this method to return **localized** strings.
    /// * Localized all the error strings in ``BaseConstants/LocalizedStrings``.
    @MainActor
    open func getErrorMessageForError(_ error: BaseError) -> String {
        error.defaultErrorMessage
    }
    
    // MARK: Other public methods
    
    /// Call this method to visually change the currently selected category.
    ///
    /// - Parameter category: The new selected category. Passing `nil` or a category not included in `currentCategories` deselects the currently selected category.
    ///
    /// This method does not trigger any request. It only affects visual aspect of the views for the affected categories.
    @MainActor
    public func setSelectedCategory(_ category: Category?) {
        if let category, let index = currentCategories.firstIndex(of: category) {
            appView?.setSelectedCategory(index: index, scrollPosition: .centeredHorizontally)
        } else {
            appView?.deselectSelectedCategory()
        }
    }
    
    /// Shows a toast on top of the FleksyApp and **returns immediately**.
    /// - Parameters:
    ///   - message: The message to show in toast.
    ///   - alignment: The alignment of the toast.
    ///   - showLoader: Whether the toast should include an animating activity indicator.
    ///   - animationDuration: The duration of the fade in animation. Defaults to `0.3` seconds.
    ///   - delay: The delay to show the toast. Defaults to no delay.
    ///
    /// It's your responsibility to hide the toast as soon as it makes sense (see ``hideToast(animationDuration:delay:)`` and ``hideToastAndWait(animationDuration:delay:)``).
    ///
    /// The UI is disabled while the toast is being shown.
    ///
    /// If there's currently a toast being shown and a new one with new parameters needs to be shown, there's no need to call hide before. You can simply call any of the `show` methods again with the new parameters.
    @MainActor
    public func showToast(message: String, alignment: Alignment = .top, showLoader: Bool = false, animationDuration: TimeInterval = 0.3, delay: TimeInterval = 0) {
        appView?.showToast(message: message, alignment: alignment, showLoader: showLoader, animationDuration: animationDuration, delay: delay)
    }
    
    /// Shows a toast on top of the FleksyApp and **returns asynchronously** once the show animations have finished.
    /// - Parameters:
    ///   - message: The message to show in toast.
    ///   - alignment: The alignment of the toast.
    ///   - showLoader: Whether the toast should include an animating activity indicator.
    ///   - animationDuration: The duration of the fade in animation. Defaults to `0.3` seconds.
    ///   - delay: The delay to show the toast. Defaults to no delay.
    ///
    /// It's your responsibility to hide the toast as soon as it makes sense (see ``hideToast(animationDuration:delay:)`` and ``hideToastAndWait(animationDuration:delay:)``).
    ///
    /// The UI is disabled while the toast is being shown.
    ///
    /// If there's currently a toast being shown and a new one with new parameters needs to be shown, there's no need to call hide before. You can simply call any of the `show` methods again with the new parameters.
    public func showToastAndWait(message: String, alignment: Alignment = .top, showLoader: Bool = false, animationDuration: TimeInterval = 0.3, delay: TimeInterval = 0) async {
        await appView?.showToastAndWait(message: message, alignment: alignment, showLoader: showLoader, animationDuration: animationDuration, delay: delay)
    }
    
    /// Hides the toast and **returns immediately**.
    /// - Parameter animationDuration: The duration of the fade in animation. Defaults to `0.3` seconds.
    ///
    /// This method does nothing if no toast is being shown.
    @MainActor
    public func hideToast(animationDuration: TimeInterval = 0.3, delay: TimeInterval = 0) {
        appView?.hideToast(animationDuration: animationDuration, delay: delay)
    }
    
    /// Hides the toast and **returns asynchronously** once the hiding animation has finished.
    /// - Parameter animationDuration: The duration of the fade in animation. Defaults to `0.3` seconds.
    ///
    /// This method does nothing and returns immediately if no toast is being shown.
    public func hideToastAndWait(animationDuration: TimeInterval = 0.3, delay: TimeInterval = 0) async {
        await appView?.hideToastAndWait(animationDuration: animationDuration, delay: delay)
    }
    
    // MARK: - Private methods
    
    @discardableResult
    private func performInitialLoads() -> Task<(), Never> {
        Task(priority: .userInitiated) { [weak self] in
            await self?.appView?.showLoader()
            await self?.performGetCategories().value
            self?.performDefaultRequest()
        }
    }
    
    @discardableResult
    private func performDefaultRequest() -> BaseContentTask {
        resetLoadFirstPage { [weak self] pagination in
            guard let self else {
                return .failure(.cancelled)
            }
            return await self.getDefaultContentsFor(pagination: pagination)
        }
    }
    
    @discardableResult
    private func performSearchRequest(query: String) -> BaseContentTask {
        resetLoadFirstPage { [weak self] pagination in
            guard let self else {
                return .failure(.cancelled)
            }
            return await self.getContentsFor(query: query, pagination: pagination)
        }
    }
    
    @discardableResult
    private func performCategoryRequest(_ category: Category) -> BaseContentTask {
        resetLoadFirstPage { [weak self] pagination in
            guard let self else {
                return .failure(.cancelled)
            }
            return await self.getContentsFor(category: category, pagination: pagination)
        }
    }
    
    private var activeContentsTask: BaseContentTask?
    private func resetLoadFirstPage(contentsLoader: @escaping (Pagination) async -> BaseContentResult) -> BaseContentTask {
        activeContentsTask?.cancel()
        currentContentsLoader = contentsLoader
        
        let firstPagination = Pagination(limit: configuration.requestLimit)
        return loadPagination(firstPagination, contentsLoader: contentsLoader)
    }
    
    @discardableResult
    private func loadNextPage() -> BaseContentTask {
        guard let pagination, let currentContentsLoader else {
            return performDefaultRequest()
        }
        return loadPagination(pagination.next(), contentsLoader: currentContentsLoader)
    }
    
    /// Loads a new pagination with the given `contentsLoader`.
    /// - Parameters:
    ///   - pagination: The pagination to load. If it's the first page, the loader is shown and the `currentContents` array is initially reset to an empty array.
    ///   - contentsLoader: The closure that actually loads the contents.
    /// - Returns: The execution task.
    @discardableResult
    private func loadPagination(_ pagination: Pagination, contentsLoader: @escaping ((Pagination) async -> BaseContentResult)) -> BaseContentTask {
        if let activeContentsTask, !activeContentsTask.isCancelled {
            return activeContentsTask
        }
        
        let task = Task(priority: .userInitiated) { () -> BaseContentResult in
            if pagination.isFirstPage {
                await MainActor.run { [weak self] in
                    self?.appView?.showLoader()
                    self?.currentContents = []
                }
            }
            
            let result = await contentsLoader(pagination)
            
            guard !Task.isCancelled else {
                return .failure(.cancelled)
            }
            
            return await MainActor.run { [weak self] () -> BaseContentResult in
                guard let self else { return result }
                switch result {
                case .success(let contents):
                    self.appendContentsRemovingDuplicates(contents)
                    self.appView?.hideErrorMessage()
                    self.appView?.hideLoader()
                case .failure(let error):
                    let errorMsg = self.getErrorMessageForError(error)
                    self.appView?.showErrorMessage(errorMsg)
                    self.appView?.hideLoader()
                }
                self.activeContentsTask = nil
                return result
            }
        }
        activeContentsTask = task
        self.pagination = pagination
        return task
    }
        
    private var activeCategoriesTask: Task<Void, Never>?
    
    @discardableResult
    private func performGetCategories() -> Task<Void, Never> {
        if let activeCategoriesTask {
            return activeCategoriesTask
        }
        let categoriesTask = Task { [weak self] in
            guard let categories = await self?.getCategories() else { return }
            await MainActor.run { [weak self] in
                self?.currentCategories = categories
                self?.appView?.reloadCategories(categories)
            }
        }
        activeCategoriesTask = categoriesTask
        return categoriesTask
    }
    
    /// This method appends `contents` to `currentContents` but removing duplicates (in case the API sometimes returns items with the same identifier).
    @MainActor
    private func appendContentsRemovingDuplicates(_ contents: [ContentType]) {
        for newItem in contents {
            if currentContents.contains(where: {
                $0.id == newItem.id
            }) {
                print("Skipped adding duplicated content: \(newItem)")
            } else {
                currentContents.append(newItem)
            }
        }
    }
}

// MARK: - AppTextFieldDelegate

extension BaseApp: AppTextFieldDelegate {
    
    /// The placeholder used by app for the in-keyboard text field when showing the app in `KeyboardAppViewMode.frame` mode with `TopBarMode.appTextField` top bar mode.
    ///
    /// - Important: This property can't be overriden. Configure this string with the ``BaseConfiguration`` used to initialize the app. This method returns the ``BaseConfiguration/searchPlaceholder``.
    public var placeholder: String? {
        configuration.searchPlaceholder
    }
    
    /// This method is called by the KeyboardSDK whenever the user changes the text in the in-keyboard text field (during `KeyboardAppViewMode.frame` mode with `TopBarMode.appTextField` top bar mode).
    ///
    /// - Important: Do not call this method form the ``BaseApp`` subclass.
    public func onTextDidChange(_ text: String?) {
        if text == nil || text?.isEmpty == true {
            performDefaultRequest()
        }
    }
    
    /// This method is called by the KeyboardSDK if the taps the return button while the in-keyboard text field has the focus (during `KeyboardAppViewMode.frame` mode with `TopBarMode.appTextField` top bar mode).
    ///
    /// - Important: Do not call this method form the ``BaseApp`` subclass.
    public func onReturnKeyAction(_ text: String?) {
        if let text, !text.isEmpty {
            performSearchRequest(query: text)
        } else {
            performDefaultRequest()
        }
    }
    
    /// This method is called by the KeyboardSDK the close button in the app during `KeyboardAppViewMode.frame` mode with `TopBarMode.appTextField` top bar mode. The implementation of the base app closes the app.
    ///
    /// - Important: Do not call this method form the ``BaseApp`` subclass.
    public func onCloseAction() {
        appListener?.hide()
    }
}

// MARK: - BaseAppViewDelegate

extension BaseApp: BaseAppViewDelegate {
    
    var allowAudioInVideoCells: Bool { allowAudioInVideoPreviews }
    
    /// Method called when the user taps the search button in the app during `KeyboardAppViewMode.fullCover` mode. The base app changes the view mode to `KeyboardAppViewMode.frame` with `TopBarMode.appTextField` top bar mode.
    ///
    /// - Important: Do not call this method form the ``BaseApp`` subclass.
    func onSearchAction() {
        appListener?.show(mode: .frame(barMode: .appTextField(delegate: self)))
    }
    
    // MARK: - ListViewDelegate
    
    
    @MainActor
    func localURLForContentAt(index: Int) -> URL? {
        guard index < currentContents.count else {
            return nil
        }
        let content = currentContents[index]
        guard case .remoteMedia(let remoteMedia) = content.contentType else {
            return nil
        }
        return mediaManager.localFileURL(id: content.id, for: remoteMedia)
    }
    
    func loadContentAt(index: Int) async {
        let currentContents = await currentContents
        guard index < currentContents.count else {
            return
        }
        let content = currentContents[index]
        guard case .remoteMedia(let remoteMedia) = content.contentType else {
            return
        }
        _ = await mediaManager.downloadMediaIfNeeded(id: content.id, for: remoteMedia)
    }
    
    func prefetchItemsAt(indexes: [Int]) {
        let contentsCount = currentContents.count
        var mutableContentsToFetch = [ContentType]()
        var mutableNotYetAvailableIndexes = [Int]()
        
        indexes.forEach {
            if $0 < contentsCount {
                mutableContentsToFetch.append(currentContents[$0])
            } else {
                mutableNotYetAvailableIndexes.append($0)
            }
        }
        
        let contentsToFetch = mutableContentsToFetch
        
        if !contentsToFetch.isEmpty {
            Task.detached(priority: .userInitiated) {
                await withTaskGroup(of: Void.self) { group in
                    for content in contentsToFetch {
                        if case .remoteMedia(let remoteMedia) = content.contentType {
                            group.addTask(priority: .userInitiated) { [weak self] in
                                _ = await self?.mediaManager.downloadMediaIfNeeded(id: content.id, for: remoteMedia)
                            }
                        }
                    }
                }
            }
        }
        
        let notYetAvailableIndexes = mutableNotYetAvailableIndexes
        if !notYetAvailableIndexes.isEmpty {
            Task.detached(priority: .userInitiated) { [weak self] in
                let result = await self?.loadNextPage().value
                if case .success(let contentResult) = result, !contentResult.isEmpty {
                    await self?.prefetchItemsAt(indexes: notYetAvailableIndexes)
                }
            }
        }
    }
    
    func willShowItemAt(index: Int) {
        if index >= currentContents.count - 2 {
            loadNextPage()
        }
    }
    
    func cancelPrefetchOfItemsAt(indexes: [Int]) {
        let currentContents = currentContents
        Task.detached {
            await withTaskGroup(of: Void.self) { group in
                indexes.lazy
                    .filter { $0 < currentContents.count }
                    .forEach {
                        let result = currentContents[$0]
                        group.addTask { [weak self] in
                            await self?.mediaManager.cancelMediaDownload(id: result.id)
                        }
                    }
            }
        }
    }
    
    @MainActor
    func didSelectItemAt(index: Int) {
        guard index < currentContents.count else { return }
        didSelectContent(currentContents[index])
    }
    
    @MainActor
    func absoluteSizeForItemAt(index: Int) -> CGSize {
        guard index < currentContents.count else {
            return .zero
        }
        switch currentContents[index].contentType {
        case .remoteMedia(let remoteMedia):
            return CGSize(width: remoteMedia.width, height: remoteMedia.height)
        case .html(_, let width, let height):
            return CGSize(width: width, height: height)
        }
    }
    
    func willStartVideoPlaybackInVideoCell() {
        saveCurrentAVAudioSessionCategoryStatusIfNeeded()
        if AVAudioSession.sharedInstance().category == .soloAmbient {
            /// If the category is `.soloAmbient` (which is the default category), playing a video (even muted)
            /// stops any other audio that can be playing on the device by any other app (e.g. music, podcast, etc.)
            /// We change the category to `.ambient` in order to prevent a muted video playback on the
            /// Keyboard app from stopping the current audio playback on the device.
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient)
            } catch {
                print("Error when setting the AVAudioSession category for playing video: \(error)")
            }
        }
    }

    func willUnmuteAudioInVideoCell() {
        saveCurrentAVAudioSessionCategoryStatusIfNeeded()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error when setting the AVAudioSession category for enabling video sound: \(error)")
        }
    }
    
    private func saveCurrentAVAudioSessionCategoryStatusIfNeeded() {
        if restoreAudioSessionCallback == nil {
            let originalCategory = AVAudioSession.sharedInstance().category
            let originalMode = AVAudioSession.sharedInstance().mode
            let originalPolicy = AVAudioSession.sharedInstance().routeSharingPolicy
            let originalOptions = AVAudioSession.sharedInstance().categoryOptions
            restoreAudioSessionCallback = {
                try? AVAudioSession.sharedInstance().setCategory(originalCategory, mode: originalMode, policy: originalPolicy, options: originalOptions)
            }
        }
    }
    
    // MARK: - CategoryViewDelegate
    
    func didSelectCategoryAt(index: Int) {
        performCategoryRequest(currentCategories[index])
    }
}
