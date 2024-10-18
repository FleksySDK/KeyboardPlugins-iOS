//  BaseAppView.swift
//  FleksyApps
// 
//  Copyright © 2023 Thingthing. All rights reserved.
//
    

import UIKit
import FleksyAppsCore
import SwiftUI

protocol BaseAppViewDelegate: AnyObject, ListViewDelegate, CategoryViewDelegate {
    @MainActor
    func onSearchAction()
    
    @MainActor
    func onCloseAction()
}

/// An object that manages the content of a FleksyApp view.
class BaseAppView<Content: BaseContent, Category: BaseCategory>: UIView {
    
    private static var actionsViewHeight: CGFloat { 44 }
    private static var categoriesViewHeight: CGFloat { 44 }

    var appTheme: AppTheme {
        didSet {
            listView.appTheme = appTheme
            categoryView.appTheme = appTheme
            updateColors()
            updateFont()
        }
    }
    
    var selectedCategoryIndex: Int? {
        categoryView.selectedIndex
    }
    
    private weak var delegate: BaseAppViewDelegate?
    
    private let listViewContainer = UIView()
    private let listView: ListView<Content>

    private lazy var toastController: UIHostingController<ToastContainer> = {
        let toastContainer = ToastContainer(appTheme: appTheme)
        let hostingController = UIHostingController(rootView: toastContainer)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        hostingController.view.backgroundColor = .clear
        hostingController.view.isHidden = true
        hostingController.view.alpha = 0 // To be able to animate the first time it is shown
        return hostingController
    }()
    
    private var toastContainer: ToastContainer {
        toastController.rootView
    }
    
    private let categoryViewContainer = UIView()
    private let categoryView: CategoryView<Category>
    
    private let searchButton = UIButton()
    private let closeButton = UIButton()
    private let errorView = UIView()
    private let errorLabel = UILabel()
    private let loader = UIActivityIndicatorView(style: .large)
    private lazy var actionsViewContainer: UIView = {
        let stackView = UIStackView(arrangedSubviews: [searchButton, closeButton])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    init(viewMode: KeyboardAppViewMode, appTheme: AppTheme, delegate: BaseAppViewDelegate, listViewConfiguration: ListViewConfiguration, searchText: String) {
        self.appTheme = appTheme
        self.delegate = delegate
        
        self.listView = ListView(configuration: listViewConfiguration, appTheme: appTheme, delegate: delegate)
        
        self.categoryView = CategoryView(appTheme: appTheme, delegate: delegate)
        
        super.init(frame: .zero)
        
        setup(searchText: searchText)
        updateForViewMode(viewMode, listViewConfiguration: listViewConfiguration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Interface
    
    func updateForViewMode(_ viewMode: KeyboardAppViewMode, listViewConfiguration: ListViewConfiguration) {
        switch viewMode {
        case .fullCover:
            actionsViewContainer.isHidden = false
        case .frame:
            actionsViewContainer.isHidden = true
        @unknown default:
            actionsViewContainer.isHidden = true
        }
        
        listView.configuration = listViewConfiguration
    }
    
    @MainActor
    func reloadContents(_ contents: [Content]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Content>()
        snapshot.appendSections([0])
        snapshot.appendItems(contents)
        let animateDiffs = !contents.isEmpty && listView.frame.width > 0 && listView.frame.height > 0
        listView.dataSource.apply(snapshot, animatingDifferences: animateDiffs)
        if contents.isEmpty {
            listView.scrollToStart()
        }
    }
        
    @MainActor
    func reloadCategories(_ categories: [Category]) {
        if categories.isEmpty {
            categoryViewContainer.isHidden = true
        } else {
            categoryViewContainer.isHidden = false
            var snapshot = NSDiffableDataSourceSnapshot<Int, Category>()
            snapshot.appendSections([0])
            snapshot.appendItems(categories)
            let animateDiffs = !categories.isEmpty && categoryView.frame.width > 0 && categoryView.frame.height > 0
            categoryView.dataSource.apply(snapshot, animatingDifferences: animateDiffs)
            categoryView.scrollToStart()
        }
    }
    
    @MainActor
    func setSelectedCategory(index: Int, scrollPosition: UICollectionView.ScrollPosition) {
        categoryView.setSelectedCategory(index: index, scrollPosition: scrollPosition)
    }
    
    @MainActor
    func deselectSelectedCategory() {
        categoryView.deselectSelectedCategory()
    }
    
    /// Shows the loader. This method also calls ``hideErrorMessage()`` because it is assumed that while content is loading, no error message should be shown.
    @MainActor
    func showLoader() {
        hideErrorMessage()
        loader.startAnimating()
        listView.isHidden = true
    }
    
    @MainActor
    func hideLoader() {
        loader.stopAnimating()
        listView.isHidden = false
    }
    
    @MainActor
    func showErrorMessage(_ msg: String) {
        errorLabel.text = msg
        errorView.isHidden = false
    }
    
    @MainActor
    func hideErrorMessage() {
        errorView.isHidden = true
    }
    
    @MainActor
    func showToast(message: String, alignment: Alignment, showLoader: Bool, animationDuration: TimeInterval, delay: TimeInterval) {
        let currentlyHidden = self.toastController.view.isHidden
        toastContainer.update(message: message, alignment: alignment, showingLoader: showLoader,  animated: !currentlyHidden)
        self.toastController.view.isHidden = false
        UIView.animate(withDuration: animationDuration, delay: delay) { [weak self] in
            self?.toastController.view.alpha = 1
        }
    }
    
    func showToastAndWait(message: String, alignment: Alignment, showLoader: Bool, animationDuration: TimeInterval, delay: TimeInterval) async {
        let currentlyHidden = self.toastController.view.isHidden
        toastContainer.update(message: message, alignment: alignment, showingLoader: showLoader, animated: !currentlyHidden)
        self.toastController.view.isHidden = false
        await UIView.animateKeyframes(withDuration: animationDuration, delay: delay, options: .beginFromCurrentState) { [weak self] in
            self?.toastController.view.alpha = 1
        }
    }
    
    @MainActor
    func hideToast(animationDuration: TimeInterval, delay: TimeInterval) {
        UIView.animate(withDuration: animationDuration, delay: delay) { [weak self] in
            self?.toastController.view.alpha = 0
        } completion: { [weak self] finished in
            if finished {
                self?.toastController.view.isHidden = true
            }
        }
    }
    
    func hideToastAndWait(animationDuration: TimeInterval, delay: TimeInterval) async {
        let finished = await UIView.animateKeyframes(withDuration: animationDuration, delay: delay, options: .beginFromCurrentState) { [weak self] in
            self?.toastController.view.alpha = 0
        }
        if finished {
            toastController.view.isHidden = true
        }
    }
    
    // MARK: - Actions
    
    @objc func searchAction() {
        delegate?.onSearchAction()
    }
    
    @objc func closeAction() {
        delegate?.onCloseAction()
    }
    
    // MARK: - Private methods
    
    private func setup(searchText: String) {
        // Views config
        searchButton.contentMode = .scaleAspectFit
        searchButton.titleLabel?.numberOfLines = 1
        searchButton.contentHorizontalAlignment = .leading
        searchButton.setImage(BaseConstants.Images.searchIcon, for: .normal)
        searchButton.setTitle(searchText, for: .normal)
        searchButton.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
        searchButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        searchButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        
        closeButton.contentMode = .scaleAspectFit
        closeButton.contentHorizontalAlignment = .trailing
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        closeButton.setImage(BaseConstants.Images.closeButtonIcon, for: .normal)
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        
        errorView.layer.masksToBounds = true
        errorView.layer.cornerRadius = 3
        
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.adjustsFontSizeToFitWidth = true
        errorLabel.minimumScaleFactor = 0.7
        errorLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        loader.hidesWhenStopped = true
        
        let mainStackView = UIStackView(arrangedSubviews: [actionsViewContainer, listViewContainer, categoryViewContainer])
        mainStackView.axis = .vertical
        mainStackView.alignment = .fill
        mainStackView.distribution = .fill
        
        // Autolayout
        
        listView.translatesAutoresizingMaskIntoConstraints = false
        listViewContainer.addSubview(listView)
        
        categoryView.translatesAutoresizingMaskIntoConstraints = false
        categoryViewContainer.addSubview(categoryView)
        
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStackView)
        
        loader.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loader)
        
        errorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(errorView)
        
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorView.addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Self.actionsViewHeight),
            actionsViewContainer.heightAnchor.constraint(equalToConstant: Self.actionsViewHeight),
            categoryView.heightAnchor.constraint(equalToConstant: Self.categoriesViewHeight),
            
            listView.topAnchor.constraint(equalTo: listViewContainer.topAnchor),
            listView.bottomAnchor.constraint(equalTo: listViewContainer.bottomAnchor),
            listView.leadingAnchor.constraint(equalTo: listViewContainer.leadingAnchor),
            listView.trailingAnchor.constraint(equalTo: listViewContainer.trailingAnchor),
            
            categoryView.topAnchor.constraint(equalTo: categoryViewContainer.topAnchor),
            categoryView.bottomAnchor.constraint(equalTo: categoryViewContainer.bottomAnchor),
            categoryView.leadingAnchor.constraint(equalTo: categoryViewContainer.leadingAnchor),
            categoryView.trailingAnchor.constraint(equalTo: categoryViewContainer.trailingAnchor),
            
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            errorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            errorView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 3/4),
            errorView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 10),
            errorView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10),
            
            errorLabel.topAnchor.constraint(equalTo: errorView.topAnchor, constant: 10),
            errorLabel.bottomAnchor.constraint(equalTo: errorView.bottomAnchor, constant: -10),
            errorLabel.leadingAnchor.constraint(equalTo: errorView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: errorView.trailingAnchor, constant: -20),
            
            loader.centerYAnchor.constraint(equalTo: listView.centerYAnchor),
            loader.centerXAnchor.constraint(equalTo: listView.centerXAnchor),
        ])
        
        listViewContainer.backgroundColor = .clear
        categoryViewContainer.backgroundColor = .clear
        
        updateColors()
        updateFont()
        
        errorView.isHidden = true
    }

    private func updateColors() {
        backgroundColor = appTheme.background
        tintColor = appTheme.foreground
        
        closeButton.tintColor = appTheme.foreground
        closeButton.backgroundColor = .clear
        
        searchButton.tintColor = appTheme.foreground
        searchButton.backgroundColor = .clear
        searchButton.setTitleColor(appTheme.foreground, for: .normal)
        
        errorView.backgroundColor = appTheme.foreground
        errorLabel.textColor = appTheme.accent
        
        loader.color = appTheme.foreground
    }
    
    private func updateFont() {
        let bodyFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: appTheme.font.withSize(UIFont.labelFontSize))
        errorLabel.font = bodyFont
        searchButton.titleLabel?.font = bodyFont
    }
}
