/*
 *  license-start
 *  
 *  Copyright (C) 2021 Ministero della Salute and all other contributors
 *  
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  
 *      http://www.apache.org/licenses/LICENSE-2.0
 *  
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
*/

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
