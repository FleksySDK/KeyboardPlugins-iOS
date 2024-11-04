//  MosaicLayout.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//


import UIKit

protocol MosaicLayoutDelegate: AnyObject {
    func collectionView(
        _ collectionView: UICollectionView,
        absoluteSizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
}

/// Grid layout with support for one section only.
class MosaicLayout: UICollectionViewLayout {
    weak var delegate: MosaicLayoutDelegate?
    
    var direction: UICollectionView.ScrollDirection
    
    private var numberOfBands: Int
    private var cellPadding: CGFloat
    
    private var cache: [UICollectionViewLayoutAttributes] = []
    
    private var contentLengths: [CGFloat] = [0]
    private var contentSideLength: CGFloat {
        guard let collectionView else {
            return 0
        }
        var computedContentLength: CGFloat
        let insets = collectionView.contentInset
        switch self.direction {
        case .vertical:
            computedContentLength = collectionView.bounds.width - (insets.left + insets.right)
        case .horizontal:
            computedContentLength = collectionView.bounds.height - (insets.top + insets.bottom)
        @unknown default:
            fatalError()
        }
        return max(computedContentLength, 0)
    }
    
    override var collectionViewContentSize: CGSize {
        let size: CGSize
        switch self.direction {
        case .vertical:
            size = CGSize(width: self.contentSideLength, height: self.contentLengths.max() ?? 0)
        case .horizontal:
            size = CGSize(width: self.contentLengths.max() ?? 0, height: self.contentSideLength)
        @unknown default:
            fatalError()
        }
        return size
    }
    
    init(numberOfBands: Int, cellPadding: CGFloat, direction: UICollectionView.ScrollDirection = .vertical) {
        self.numberOfBands = numberOfBands
        self.cellPadding = cellPadding
        self.direction = direction
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        guard cache.isEmpty,
              let collectionView, collectionView.numberOfSections > 0
        else { return }
        
        self.contentLengths = .init(repeating: 0, count: numberOfBands)
        
        let indexPaths = (0..<collectionView.numberOfItems(inSection: 0)).map {
            IndexPath(item: $0, section: 0)
        }
        
        updateForContentsAtIndexPaths(indexPaths)
    }
    
    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        let newItems = updateItems.filter({ $0.indexPathAfterUpdate != $0.indexPathBeforeUpdate })
        guard let collectionView = self.collectionView,
              !newItems.isEmpty
        else { return }
        
        let oldIndices = newItems.compactMap { $0.indexPathBeforeUpdate }
            .sorted { $0.item < $1.item }
        let newIndices = newItems
            .compactMap { $0.indexPathAfterUpdate }
            .filter { $0.item != NSNotFound }
            .sorted { $0.item < $1.item }
        
        let minUpdatedIndex = (oldIndices + newIndices)
            .map { $0.item }
            .min() ?? self.cache.count
        if minUpdatedIndex < self.cache.count {
            self.resetLayout()
            return
        }
        
        updateForContentsAtIndexPaths(newIndices)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        super.layoutAttributesForElements(in: rect)
        var visibleLayoutAttributes: [UICollectionViewLayoutAttributes] = []
        
        // Loop through the cache and look for items in the rect
        for attributes in self.cache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }
        return visibleLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard self.cache.count > indexPath.item
        else { return nil }
        return self.cache[indexPath.item]
    }
    
    func resetLayout() {
        self.cache = []
        self.prepare()
    }
    
    private func updateForContentsAtIndexPaths(_ indexPaths: [IndexPath]) {
        guard let collectionView, !indexPaths.isEmpty else {
            return
        }
        let bandSide = contentSideLength / CGFloat(numberOfBands)
        var sideOffset: [CGFloat] = []
        for band in 0..<numberOfBands {
            sideOffset.append(CGFloat(band) * bandSide)
        }
        var band = contentLengths.enumerated().min { $0.element < $1.element }?.offset ?? 0
        
        indexPaths.forEach {
            let itemSize = delegate?.collectionView(collectionView, absoluteSizeForItemAtIndexPath: $0) ?? .zero
            var length: CGFloat
            let frame: CGRect
            switch direction {
            case .vertical:
                length = itemSize.width > 0 ? (bandSide - 2 * cellPadding) * (itemSize.height / itemSize.width) + 2 * cellPadding : 0
                length = min(length, UIScreen.main.bounds.height - (collectionView.contentInset.top + collectionView.contentInset.bottom))
                frame = CGRect(x: sideOffset[band], y: contentLengths[band],
                               width: bandSide, height: length)
            case .horizontal:
                length = itemSize.height > 0 ? (bandSide - 2 * cellPadding) * (itemSize.width / itemSize.height) + 2 * cellPadding : 0
                length = min(length, UIScreen.main.bounds.width - (collectionView.contentInset.left + collectionView.contentInset.right))
                frame = CGRect(x: contentLengths[band], y: sideOffset[band],
                               width: length, height: bandSide)
            @unknown default:
                fatalError()
            }
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: $0)
            attributes.frame = insetFrame.isEmpty ? frame : insetFrame
            if $0.item < cache.endIndex {
                cache[$0.item] = attributes
            } else {
                cache.append(attributes)
            }
            
            switch direction {
            case .vertical:
                contentLengths[band] = max(contentLengths[band], frame.maxY)
            case .horizontal:
                contentLengths[band] = max(contentLengths[band], frame.maxX)
            @unknown default:
                fatalError()
            }
            
            band = contentLengths.enumerated().min { $0.element < $1.element }?.offset ?? 0
        }
    }
}
