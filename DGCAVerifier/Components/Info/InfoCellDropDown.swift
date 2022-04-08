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
//  InfoCellDropDown.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 07.09.2021.
//  
        

import UIKit
import DGCCoreLibrary

typealias DropDownBlock = (Bool) -> Void

class InfoCellDropDown: UITableViewCell {
  private enum Constants {
    static let iconCollapsed = "icon_collapsed"
    static let iconExpanded = "icon_expanded"
  }
    
  @IBOutlet fileprivate weak var headerLabel: UILabel!
  @IBOutlet fileprivate weak var contentLabel: UILabel!
  @IBOutlet fileprivate weak var dropDownButton: UIButton!
    
  private var dropDownBlock: DropDownBlock?
  private var info: InfoSection? {
    didSet {
      setupView()
    }
  }
    
  func setupCell(with info: InfoSection, dropDownBlock: @escaping DropDownBlock) {
    self.info = info
    self.dropDownBlock = dropDownBlock
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    info = nil
    dropDownBlock = nil
  }
  
  @IBAction func dropDownUpAction(_ sender: Any) {
    info?.isExpanded = !info!.isExpanded
    setDropDownIcon()
    dropDownBlock?(info!.isExpanded)
  }
  
  // MARK: Private methods
  private func setupView() {
    guard let info = info else { clearView(); return }
    
    setDropDownIcon()
    headerLabel?.text = info.header
    contentLabel?.text = info.content
  }
    
  private func clearView() {
    headerLabel.text = ""
    contentLabel.text = ""
  }
    
  private func setDropDownIcon() {
    guard let info = info else { return }

    if !info.isExpanded {
      dropDownButton.setImage(UIImage(named: Constants.iconCollapsed), for: .normal)
    } else {
      dropDownButton.setImage(UIImage(named: Constants.iconExpanded), for: .normal)
    }
  }
}
