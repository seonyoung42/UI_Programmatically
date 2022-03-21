//
//  DetailListCell.swift
//  FindConvenientStore
//
//  Created by 장선영 on 2022/03/10.
//

import UIKit
import SnapKit

class DetailListCell: UITableViewCell {
    let placeNameLabel = UILabel()
    let addressLabel = UILabel()
    let distanceLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        attribute()
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setData(_ data: DetailListCellData) {
        placeNameLabel.text = data.placeName
        addressLabel.text = data.address
        distanceLabel.text = data.distance
    }

    private func attribute() {
        backgroundColor = .white

        placeNameLabel.font = .systemFont(ofSize: 16, weight: .bold)

        addressLabel.font = .systemFont(ofSize:14)
        addressLabel.textColor = .gray

        distanceLabel.font = .systemFont(ofSize: 12, weight: .light)
    }

    private func layout() {
        let labelStackView = UIStackView(arrangedSubviews: [placeNameLabel,addressLabel])
        labelStackView.axis = .vertical
        labelStackView.spacing = 3

        [labelStackView,distanceLabel].forEach {
            contentView.addSubview($0)
        }

        labelStackView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.top.equalToSuperview().inset(12)
        }

        distanceLabel.snp.makeConstraints {
//            $0.leading.equalTo(labelStackView.snp.trailing).offset(10)
            $0.centerY.equalTo(labelStackView)
            $0.trailing.equalToSuperview().inset(20)
        }

    }
}
