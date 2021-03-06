//
//  FeatureSectionView.swift
//  AppstoreStyle
//
//  Created by 장선영 on 2022/01/23.
//

import UIKit

final class FeatureSectionView: UIView {
    
    private var featureList = [Feature]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    private lazy var collectionView : UICollectionView = {
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal

        let width = UIScreen.main.bounds.width - 32
        layout.itemSize = CGSize(width: width, height: width)
        let insetValue : CGFloat = 16.0
        layout.sectionInset = .init(top: 0, left: insetValue, bottom: 0, right: insetValue)
        layout.minimumLineSpacing = 32.0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(FeatureSectionCollectionViewCell.self, forCellWithReuseIdentifier: "FeatureSectionCollectionViewCell")
        
        return collectionView
    }()
    
    private let separatorView = SeparatorView(frame: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        fetchData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FeatureSectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        featureList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeatureSectionCollectionViewCell", for: indexPath) as? FeatureSectionCollectionViewCell else { return UICollectionViewCell() }
        let feature = featureList[indexPath.item]
        cell.setup(feature)
        
        return cell
    }
}

private extension FeatureSectionView {
    func setupView() {
        addSubview(collectionView)
        addSubview(separatorView)
        
        collectionView.snp.makeConstraints{
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalToSuperview().inset(16.0)
            $0.height.equalTo(self.snp.width)
        }
        
        separatorView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(collectionView.snp.bottom).offset(16.0)
        }
    }
}

// fetch Feature data
private extension FeatureSectionView {
    func fetchData() {
        guard let url = Bundle.main.url(forResource: "Feature", withExtension: "plist") else { return }
        
        do {
            let data = try Data(contentsOf: url)
            let result = try PropertyListDecoder().decode([Feature].self, from: data)
            self.featureList = result
        } catch {
            
        }
    }
}
