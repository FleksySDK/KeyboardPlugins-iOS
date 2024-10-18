//  ListView.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//
    

import UIKit
import FleksyAppsCore

protocol ListViewDelegate: AnyObject {
    
    var allowAudioInVideoCells: Bool { get }
    
    /// Always return the local URL of the file, even if it hasn't been downloaded yet.
    @MainActor
    func localURLForContentAt(index: Int) -> URL?
    
    /// Tells the delegate that the still-unavailable content at `index` needs to shown now.
    ///
    /// This method should return when the download of the content has finished.
    func loadContentAt(index: Int) async
    
    @MainActor
    func prefetchItemsAt(indexes: [Int])
    
    @MainActor
    func cancelPrefetchOfItemsAt(indexes: [Int])
    
    @MainActor
    func didSelectItemAt(index: Int)
    
    @MainActor
    func willShowItemAt(index: Int)
    
    @MainActor
    func absoluteSizeForItemAt(index: Int) -> CGSize
    
    func willUnmuteAudioInVideoCell()
    
    func willStartVideoPlaybackInVideoCell()
}

struct ListViewConfiguration: Equatable {
    
    /// The number of rows/columns of the collection view.
    let bands: Int
    
    /// The scroll direction of the collection view.
    let direction: UICollectionView.ScrollDirection

    /// The padding for the collection view cells.
    let cellPadding: CGFloat
    
    /// The collection view's insets from the app's view.
    let listInsets: UIEdgeInsets
    
    init(keyboardAppViewMode: KeyboardAppViewMode) {
        switch keyboardAppViewMode {
        case .fullCover:
            self.bands = 2
        case .frame:
            self.bands = 1
        @unknown default:
            self.bands = 1
        }
        self.direction = .horizontal
        self.cellPadding = 1
        self.listInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
    
    init(bands: Int, direction: UICollectionView.ScrollDirection, cellPadding: CGFloat, listInsets: UIEdgeInsets) {
        self.bands = max(bands, 1)
        self.direction = direction
        self.cellPadding = max(cellPadding, 0)
        self.listInsets = listInsets
    }
}

/// An object that manages the content of a FleksyApp list view as a vertical `UICollectionView`.
class ListView<Content: BaseContent>: UIView, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching {
    
    var configuration: ListViewConfiguration {
        didSet {
            if configuration != oldValue {
                updateLayout()
            }
        }
    }
    
    var appTheme: AppTheme {
        didSet {
            applyAppTheme()
        }
    }
    private weak var delegate: ListViewDelegate?
    
    private(set) lazy var dataSource = UICollectionViewDiffableDataSource<Int, Content>(collectionView: collectionView) { [weak self] collectionView, indexPath, category in
        self?.provideCell(collectionView:collectionView, indexPath:indexPath, content:category)
    }
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.createLayout())
    
    init(configuration: ListViewConfiguration, appTheme: AppTheme, delegate: ListViewDelegate?) {
        self.configuration = configuration
        self.appTheme = appTheme
        self.delegate = delegate
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }
    
    // MARK: - Interface
    
    func scrollToStart() {
        collectionView.setContentOffset(.zero, animated: false)
    }
    
    // MARK: - Private methods
    
    private func provideCell(collectionView: UICollectionView, indexPath: IndexPath, content: Content) -> UICollectionViewCell? {
        let cell: UICollectionViewCell?
        switch content.contentType {
        case .remoteMedia(let remoteMedia):
            switch remoteMedia.mediaType {
            case .video:
                let videoCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: VideoCell.self), for: indexPath) as? VideoCell
                videoCell?.appTheme = appTheme
                cell = videoCell
            case .image:
                let imageCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ImageCell.self), for: indexPath) as? ImageCell
                imageCell?.appTheme = appTheme
                cell = imageCell
            }
        case .html(let string, let width, let height):
            let webViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: WebViewCell.self), for: indexPath) as? WebViewCell
            webViewCell?.appTheme = appTheme
            webViewCell?.loadHTML(string, expectedContentSize: CGSize(width: width, height: height))
            cell = webViewCell
        }
        
        let index = indexPath.item
        
        assert(delegate != nil, "ListViewDelegate must be set")
        Task(priority: .userInitiated) { [weak delegate] in
            await delegate?.loadContentAt(index:index)
        }
        return cell
    }
        
    private func setup() {
        setupCollectionView()
        registerCells()
        updateLayout()
        applyAppTheme()
    }
    
    private func setupCollectionView() {
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
        collectionView.delegate = self
        collectionView.dataSource = dataSource
        collectionView.prefetchDataSource = self
        collectionView.contentInset = configuration.listInsets
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    private func registerCells() {
        self.collectionView.register(ImageCell.self, forCellWithReuseIdentifier: String(describing: ImageCell.self))
        self.collectionView.register(VideoCell.self, forCellWithReuseIdentifier: String(describing: VideoCell.self))
        self.collectionView.register(WebViewCell.self, forCellWithReuseIdentifier: String(describing: WebViewCell.self))
    }
    
    private func updateLayout() {
        self.collectionView.setCollectionViewLayout(self.createLayout(), animated: true)
    }
    
    private func applyAppTheme() {
        self.collectionView.backgroundColor = self.appTheme.background
        self.collectionView.tintColor = self.appTheme.foreground
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = MosaicLayout(numberOfBands: configuration.bands,
                                  cellPadding: configuration.cellPadding,
                                  direction: configuration.direction)
        layout.delegate = self
        return layout
    }

    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectItemAt(index: indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        assert(delegate != nil, "ListViewDelegate must be set")
        delegate?.willShowItemAt(index: indexPath.item)
        guard let delegate else {
            return
        }
        
        let index = indexPath.item

        switch cell {
        case let videoCell as VideoCell:
            if let url = delegate.localURLForContentAt(index: index),
               !videoCell.loadMedia(localURL: url, autoplay: true, audioToggle: delegate.allowAudioInVideoCells, delegate: self) {
                Task.detached {
                    await delegate.loadContentAt(index: index)
                    await videoCell.forceLoadMedia(localURL: url, autoplay: true)
                }
            }
        case let imageCell as ImageCell:
            if let url = delegate.localURLForContentAt(index: index),
               !imageCell.loadImage(localURL: url) {
                Task {
                    await delegate.loadContentAt(index: index)
                    imageCell.forceLoadImage(localURL: url)
                }
            }
        default:
            return
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoCell)?.stopPlayback()
    }

// MARK: - UICollectionViewDataSourcePrefetching
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let indexes = indexPaths.map { $0.item }
        delegate?.prefetchItemsAt(indexes: indexes)
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let indexes = indexPaths.map { $0.item }
        delegate?.cancelPrefetchOfItemsAt(indexes: indexes)
    }
}

// MARK: - MosaicLayoutDelegate

extension ListView: MosaicLayoutDelegate {
    
    func collectionView(_ collectionView: UICollectionView, absoluteSizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        delegate?.absoluteSizeForItemAt(index: indexPath.item) ?? CGSize(width: 1, height: 1)
    }
}

extension ListView: VideoCellDelegate {
    
    func videoCellWillStartPlayingVideo(_ videoCell: VideoCell) {
        delegate?.willStartVideoPlaybackInVideoCell()
    }
    
    func videoCellWillUnmuteAudio(_ videoCell: VideoCell) {
        delegate?.willUnmuteAudioInVideoCell()
        collectionView.visibleCells.forEach {
            if let otherVideoCell = $0 as? VideoCell, otherVideoCell !== videoCell {
                otherVideoCell.muteAudio()
            }
        }
    }
}
