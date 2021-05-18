//
//  ResultView.swift
//  verifier-ios
//
//

import UIKit

struct ResultItem {
    var title: String?
    var subtitle: String?
    var imageName: String?
}

class ResultView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    func configure(with item: ResultItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        if let imageName = item.imageName {
            iconImageView.image = UIImage(named: imageName)
        }
    }
}
