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
//  DebugGeneralTVC.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 07.09.2021.
//  

import UIKit
import SwiftDGC

typealias ReloadBlock = () -> Void

class DebugGeneralTVC: UITableViewCell {

  @IBOutlet weak var tableHeight: NSLayoutConstraint!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var view: UIView!
  
  private var needReload = true
  var reload: ReloadBlock?
  var validator: CertificateValidator?

  private var debugSection: DebugSectionModel? {
    didSet {
      setupView()
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    tableView.register(UINib(nibName: "InfoCell", bundle: nil), forCellReuseIdentifier: "InfoCell")
    tableView.register(UINib(nibName: "InfoCellDropDown", bundle: nil), forCellReuseIdentifier: "InfoCellDropDown")
    tableView.register(UINib(nibName: "RuleErrorTVC", bundle: nil), forCellReuseIdentifier: "RuleErrorTVC")
    tableView.dataSource = self
    tableView.estimatedRowHeight = 800
    tableView.rowHeight = UITableView.automaticDimension
  }
  
  private func setupView() {
    guard debugSection != nil else { return }
    
    tableView.reloadData()
    tableView.performBatchUpdates({ () -> Void in
    }, completion: { [weak self] _ in
      self?.needReload = false
      if self?.tableHeight.constant != self?.tableView.contentSize.height {
        self?.tableHeight.constant = self?.tableView.contentSize.height ?? 0
        self?.needReload = true
      }
        if self?.needReload ?? true {
          self?.reload?()
        }
      })
  }

  public func setupDebugSection(debugSection: DebugSectionModel, needReload: Bool = true) {
    self.needReload = needReload
    self.debugSection = debugSection
  }
}

extension DebugGeneralTVC: UITableViewDataSource, UITableViewDelegate {
  var listItems: [InfoSection] {
    validator?.infoSection.filter { !$0.isPrivate } ?? []
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let section: InfoSection = listItems[section]
    if section.sectionItems.count == .zero {
      return 1
    } else if !section.isExpanded {
      return 1
    } else {
      return section.sectionItems.count + 1
    }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return listItems.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var sectionInfo: InfoSection = listItems[indexPath.section]
    if sectionInfo.sectionItems.count == 0 {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath) as?
          InfoCell else { return UITableViewCell() }
        
      cell.setupCell(with: sectionInfo)
      return cell
      
    } else {
      if indexPath.row == .zero {
          guard let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCellDropDown", for: indexPath) as?
              InfoCellDropDown else { return UITableViewCell() }
          
        cell.setupCell(with: sectionInfo) { [weak self] state in
          sectionInfo.isExpanded = state
          if let row = self?.validator?.infoSection.firstIndex(where: {$0.header == sectionInfo.header}) {
            self?.validator?.infoSection[row] = sectionInfo
          }
          tableView.reloadData()
        }
        return cell
        
      } else {
          guard let cell = tableView.dequeueReusableCell(withIdentifier: "RuleErrorTVC", for: indexPath) as?
              RuleErrorTVC else { return UITableViewCell() }
        
        let item = sectionInfo.sectionItems[indexPath.row - 1]
        cell.setupCell(with: item)
        return cell
      }
    }
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.layoutIfNeeded()
  }
}
