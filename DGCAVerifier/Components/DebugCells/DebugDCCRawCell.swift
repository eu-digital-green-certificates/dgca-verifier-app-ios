//
/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-verifier-app-ios
 * ---
 * Copyright (C) 2021 T-Systems International GmbH and all other contributors
 * ---
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ---license-end
 */
//  
//  DebugDCCRawCell.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 07.09.2021.
//  
        

import UIKit
import DGCCoreLibrary
import DCCInspection
import DGCVerificationCenter

protocol DebugRawSharing: AnyObject {
  func userDidShare(text: String)
}

class DebugDCCRawCell: UITableViewCell, UIContextMenuInteractionDelegate {
  @IBOutlet fileprivate weak var rawLabel: UILabel!
  weak var delegate: DebugRawSharing?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    if #available(iOS 13.0, *) {
      let interaction = UIContextMenuInteraction(delegate: self)
      
      rawLabel.isUserInteractionEnabled = true
      rawLabel.addInteraction(interaction)
    } else {
      // Fallback on earlier versions
    }
  }

  func setupCell(for _: DebugSectionModel, cert: MultiTypeCertificate?) {
      self.certificate = cert
  }

  private var certificate: MultiTypeCertificate? {
    didSet {
      setupView()
    }
  }
  
  private func setupView() {
    guard let certificate = certificate else {
      rawLabel.text = ""
      return
    }
    rawLabel.text = (certificate.digitalCertificate as! HCert).body.description
    rawLabel.sizeToFit()
  }
  
  @objc @available(iOS 13.0, *)
  func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
    configurationForMenuAtLocation location: CGPoint)
    -> UIContextMenuConfiguration? {

    let copy = UIAction(title: "Copy Raw Data",
      image: UIImage(systemName: "doc.on.doc.fill")) { [unowned self] _ in

      UIPasteboard.general.string = self.rawLabel.text
     }

    let share = UIAction(title: "Share Raw Data",
      image: UIImage(systemName: "square.and.arrow.up.fill")) { [unowned self] _ in
      self.delegate?.userDidShare(text: self.rawLabel.text ?? "")
    }
    if let txt = self.rawLabel.text, !txt.isEmpty {
      return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
        UIMenu(title: "Actions", children: [ copy, share ])
      }
    } else {
      return nil
    }
  }
  
}
