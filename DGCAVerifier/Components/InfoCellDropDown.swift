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
//  Created by Alexandr Chernyy on 06.07.2021.
//  
import UIKit
import SwiftDGC

typealias DropDownBlock = (Bool) -> Void

final class InfoCellDropDown: UITableViewCell {
  private enum Constants {
    static let iconCollapsed = "icon_collapsed"
    static let iconExpanded = "icon_expanded"
  }
  @IBOutlet private weak var headerLabel: UILabel!
  @IBOutlet private weak var contentLabel: UILabel!
  @IBOutlet private weak var dropDownButton: UIButton!
  private var dropDownBlock: DropDownBlock?
  private var info: InfoSection  = InfoSection(header: "", content: "") {
    didSet {
      setupView()
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    clearView()
  }
    
  override func prepareForReuse() {
    super.prepareForReuse()
    clearView()
  }
    
  func setupCell(with info: InfoSection, dropDownBlock: @escaping DropDownBlock) {
    self.info = info
    self.dropDownBlock = dropDownBlock
  }
    
  private func setupView() {
    setDropDownIcon()
    headerLabel?.text = info.header
    contentLabel?.text = info.content
    let fontSize = contentLabel.font.pointSize
    let fontWeight = contentLabel.font.weight
    switch info.style {
    case .fixedWidthFont:
      if #available(iOS 13.0, *) {
        contentLabel.font = .monospacedSystemFont(ofSize: fontSize, weight: fontWeight)
      } else {
        contentLabel.font = .monospacedDigitSystemFont(ofSize: fontSize, weight: fontWeight)
      }
    default:
      contentLabel.font = .systemFont(ofSize: fontSize, weight: fontWeight)
    }
  }
    
  private func clearView() {
    headerLabel.text = ""
    contentLabel.text = ""
  }
    
  @IBAction func dropDownUpAction(_ sender: Any) {
    info.isExpanded = !info.isExpanded
    setDropDownIcon()
    dropDownBlock?(info.isExpanded)
  }
    
  private func setDropDownIcon() {
    if !info.isExpanded {
      dropDownButton.setImage(UIImage(named: Constants.iconCollapsed), for: .normal)
    } else {
      dropDownButton.setImage(UIImage(named: Constants.iconExpanded), for: .normal)
    }
  }
}
