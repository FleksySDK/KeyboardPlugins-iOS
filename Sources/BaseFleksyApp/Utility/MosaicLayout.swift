//  GiphyLayout.swift
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
              let collectionView = self.collectionView
        else { return }
                
        let bandSide = self.contentSideLength / CGFloat(self.numberOfBands)
        var sideOffset: [CGFloat] = []
        for band in 0..<self.numberOfBands {
            sideOffset.append(CGFloat(band) * bandSide)
        }
        var band = 0
        var lengthOffset: [CGFloat] = .init(repeating: 0, count: self.numberOfBands)
        self.contentLengths = lengthOffset
        
        guard collectionView.numberOfSections > 0 else { return }
        
        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            
            let itemSize = self.delegate?.collectionView(collectionView, absoluteSizeForItemAtIndexPath: indexPath) ?? CGSize(width: 1, height: 1)
            var length: CGFloat
            let frame: CGRect
            switch self.direction {
            case .vertical:
                length = self.cellPadding * 2 + bandSide * (itemSize.height / itemSize.width)
                frame = CGRect(origin: CGPoint(x: sideOffset[band], y: lengthOffset[band]),
                               size: CGSize(width: bandSide, height: length))
            case .horizontal:
                length = self.cellPadding * 2 + bandSide * (itemSize.width / itemSize.height)
                frame = CGRect(origin: CGPoint(x: lengthOffset[band], y: sideOffset[band]),
                               size: CGSize(width: length, height: bandSide))
            @unknown default:
                fatalError()
            }
            let insetFrame = frame.insetBy(dx: self.cellPadding, dy: self.cellPadding)
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            if insetFrame.origin.x.isFinite {
                attributes.frame = insetFrame
            }
            self.cache.append(attributes)
            
            switch self.direction {
            case .vertical:
                self.contentLengths[band] = max(self.contentLengths[band], frame.maxY)
            case .horizontal:
                self.contentLengths[band] = max(self.contentLengths[band], frame.maxX)
            @unknown default:
                fatalError()
            }
            lengthOffset[band] = lengthOffset[band] + length
            
            let minHeight = self.contentLengths.min() ?? 0
            band = self.contentLengths.firstIndex(of: minHeight) ?? 0
        }
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
        
        let bandSide = self.contentSideLength / CGFloat(self.numberOfBands)
        var sideOffset: [CGFloat] = []
        for band in 0..<self.numberOfBands {
            sideOffset.append(CGFloat(band) * bandSide)
        }
        let minLength = self.contentLengths.min() ?? 0
        var band: Int = self.contentLengths.firstIndex(of: minLength) ?? 0
        var lengthOffset: [CGFloat] = self.contentLengths
        
        newIndices.forEach {
            let gifSize = self.delegate?.collectionView(collectionView, absoluteSizeForItemAtIndexPath: $0) ?? CGSize(width: 1, height: 1)
            var length: CGFloat
            let frame: CGRect
            switch self.direction {
            case .vertical:
                length = self.cellPadding * 2 + bandSide * (gifSize.height / gifSize.width)
                frame = CGRect(origin: CGPoint(x: sideOffset[band], y: lengthOffset[band]),
                               size: CGSize(width: bandSide, height: length))
            case .horizontal:
                length = self.cellPadding * 2 + bandSide * (gifSize.width / gifSize.height)
                frame = CGRect(origin: CGPoint(x: lengthOffset[band], y: sideOffset[band]),
                               size: CGSize(width: length, height: bandSide))
            @unknown default:
                fatalError()
            }
            let insetFrame = frame.insetBy(dx: self.cellPadding, dy: self.cellPadding)
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: $0)
            if insetFrame.isEmpty {
                attributes.frame = frame
            } else { attributes.frame = insetFrame }
            self.cache.insert(attributes, at: $0.item)
            
            switch self.direction {
            case .vertical:
                self.contentLengths[band] = max(self.contentLengths[band], frame.maxY)
            case .horizontal:
                self.contentLengths[band] = max(self.contentLengths[band], frame.maxX)
            @unknown default:
                fatalError()
            }
            lengthOffset[band] = lengthOffset[band] + length
            
            let minLength = self.contentLengths.min() ?? 0
            band = self.contentLengths.firstIndex(of: minLength) ?? 0
        }
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
}
