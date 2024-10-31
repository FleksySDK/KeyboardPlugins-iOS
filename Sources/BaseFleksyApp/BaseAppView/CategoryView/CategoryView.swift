//  CategoryView.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//
    

import UIKit
import FleksyAppsCore

protocol CategoryViewDelegate: AnyObject {
    func didSelectCategoryAt(index: Int)
}

class CategoryView<Category: BaseCategory>: UIView, UICollectionViewDelegate {
    
    var appTheme: AppTheme {
        didSet {
            applyAppTheme()
        }
    }
    
    private weak var delegate: CategoryViewDelegate?
    
    private(set) lazy var dataSource = UICollectionViewDiffableDataSource<Int, Category>(collectionView: collectionView) { [weak self] collectionView, indexPath, category in
        self?.provideCell(collectionView: collectionView, indexPath: indexPath, category: category)
    }
    
    var selectedIndex: Int? {
        collectionView.indexPathsForSelectedItems?.first?.item
    }
    
    private let listInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.estimatedItemSize = CGSize(width: 20, height: 10)
        
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    
    // MARK: - Init
    
    init(appTheme: AppTheme, delegate: CategoryViewDelegate) {
        self.appTheme = appTheme
        self.delegate = delegate
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Interface
    
    @MainActor
    func scrollToStart() {
        collectionView.contentOffset = .zero
    }
    
    @MainActor
    func setSelectedCategory(index: Int, scrollPosition: UICollectionView.ScrollPosition) {
        collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: true, scrollPosition: scrollPosition)
    }
    
    @MainActor
    func deselectSelectedCategory() {
        guard let selectedIndex else { return }
        collectionView.deselectItem(at: IndexPath(item: selectedIndex, section: 0), animated: true)
    }
    
    // MARK: - Private methods
    
    private func provideCell(collectionView: UICollectionView, indexPath: IndexPath, category: Category) -> UICollectionViewCell? {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CategoryCell.self), for: indexPath) as? CategoryCell
        cell?.appTheme = appTheme
        cell?.isSelected = collectionView.indexPathsForSelectedItems?.contains(indexPath) == true
        cell?.load(title: category.categoryName)
        return cell
    }
    
    private func setup() {
        setupCollectionView()
        registerCells()
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
        
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.delegate = self
        collectionView.dataSource = dataSource
        collectionView.contentInset = listInsets
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    private func registerCells() {
        self.collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: String(describing: CategoryCell.self))
    }
    
    private func applyAppTheme() {
        collectionView.backgroundColor = .clear
        collectionView.tintColor = appTheme.foreground
        for cell in collectionView.visibleCells {
            (cell as? CategoryCell)?.appTheme = appTheme
        }
    }

    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectCategoryAt(index: indexPath.item)
    }
}
