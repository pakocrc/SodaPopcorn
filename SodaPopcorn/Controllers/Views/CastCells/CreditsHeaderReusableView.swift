//
//  CreditsHeaderReusableView.swift
//  SodaPopcorn
//
//  Created by Francisco Zimplifica on 10/11/21.
//

import UIKit

final class CreditsHeaderReusableView: UICollectionReusableView {
    static var reuseIdentifier: String {
        return String(describing: CreditsHeaderReusableView.self)
    }

    private let headerLabel = CustomTitleLabelView(titleText: "")

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = traitCollection.userInterfaceStyle == .light ? .white : .black

        addSubview(headerLabel)

        NSLayoutConstraint.activate([
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with headerTitle: String) {
        self.headerLabel.text = headerTitle
    }
}
