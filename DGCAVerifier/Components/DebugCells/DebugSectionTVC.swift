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
//  DebugSectionTVC.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 07.09.2021.
//  
        

import UIKit

typealias ExpandBlock = (_ debugSection: DebugSectionModel?) -> Void

class DebugSectionTVC: UITableViewCell {

  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var expandButton: UIButton!
  
  private var debugSection: DebugSectionModel? {
    didSet {
      setupView()
    }
  }
  
  var expandCallback: ExpandBlock?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    setupView()
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
    
  @IBAction func expandAction(_ sender: Any) {
    debugSection?.isExpanded = !(debugSection?.isExpanded ?? false)
    expandCallback?(debugSection)
    if debugSection?.isExpanded ?? false {
      expandButton.setTitle("-", for: .normal)
    } else {
      expandButton.setTitle("+", for: .normal)
    }
  }
  
  
  private func setupView() {
    guard let debugSection = debugSection else {
      nameLabel.text = ""
      expandButton.setTitle("-", for: .normal)
      return
    }
    if debugSection.isExpanded {
      expandButton.setTitle("-", for: .normal)
    } else {
      expandButton.setTitle("+", for: .normal)
    }
    nameLabel.text = debugSection.sectionName
  }
  
  public func setDebugSection(debugSection: DebugSectionModel) {
    self.debugSection = debugSection
  }
  
}
