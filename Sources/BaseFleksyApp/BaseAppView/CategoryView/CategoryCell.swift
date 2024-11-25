//  CategoryCell.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//
    

import UIKit
import FleksyAppsCore

class CategoryCell: UICollectionViewCell {
    
    var appTheme: AppTheme? {
        didSet {
            self.updateColors()
            self.updateFont()
        }
    }
    
    private var label = UILabel()
    private var labelView = UIView()
    
    override var isSelected: Bool {
        didSet {
            self.updateColors()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
    }
    
    func load(title: String) {
        label.text = title.localizedUppercase
    }
    
    private func setupLabel() {
        labelView.layer.cornerRadius = 8
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(labelView)
        
        let topConst = labelView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
        topConst.priority = .init(999)
        let bottConst = labelView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        bottConst.priority = .init(999)
        
        var constraints = [
            topConst,
            bottConst,
            labelView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            labelView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ]
        
        label.layer.cornerRadius = 8
        label.textAlignment = .center
        updateFont()

        label.translatesAutoresizingMaskIntoConstraints = false
        labelView.addSubview(label)

        constraints += [
            label.topAnchor.constraint(equalTo: labelView.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: labelView.bottomAnchor, constant: -4),
            label.leadingAnchor.constraint(equalTo: labelView.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: -4),
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func updateColors() {
        labelView.backgroundColor = isSelected ? appTheme?.foreground : .clear
        label.textColor = isSelected ? appTheme?.bestContrastColorForForeground : appTheme?.foreground
    }
    
    private func updateFont() {
        if let font = appTheme?.font {
            label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: font.withSize(UIFont.labelFontSize))
        } else {
            label.font = .preferredFont(forTextStyle: .body)
        }
    }
}
