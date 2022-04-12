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
//  DebugDCCSectionCell.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 07.09.2021.
//  
        

import UIKit
import DGCCoreLibrary

typealias ExpandBlock = (_ debugSection: DebugSectionModel?) -> Void

class DebugDCCSectionCell: UITableViewCell {
  @IBOutlet fileprivate weak var nameLabel: UILabel!
  @IBOutlet fileprivate weak var expandButton: UIButton!
  
  var expandCallback: ExpandBlock?
  private var debugSection: DebugSectionModel? {
    didSet {
      setupView()
    }
  }
  
  func setupCell(for debugSection: DebugSectionModel) {
    self.debugSection = debugSection
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    debugSection = nil
  }

  @IBAction func expandAction(_ sender: Any) {
    guard let debugSection = debugSection else { return }
    debugSection.isExpanded = !debugSection.isExpanded
    expandCallback?(debugSection)
    if debugSection.isExpanded {
      expandButton.setTitle("▼", for: .normal)
    } else {
      expandButton.setTitle("▶︎", for: .normal)
    }
  }
  
  // MARK: Private methods
  private func setupView() {
    guard let debugSection = debugSection else {
      clearView()
      return
    }
    if debugSection.isExpanded {
      expandButton.setTitle("▼", for: .normal)
    } else {
      expandButton.setTitle("▶︎", for: .normal)
    }
    nameLabel.text = debugSection.sectionType.rawValue
  }
  
  private func clearView() {
    nameLabel.text = ""
    expandButton.setTitle("", for: .normal)
  }
}
