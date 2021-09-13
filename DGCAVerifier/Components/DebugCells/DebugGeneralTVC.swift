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
    tableView.reloadData()
    // Initialization code
  }
  private func setupView() {
    guard let _ = debugSection else {
      return
    }
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

  public func setDebugSection(debugSection: DebugSectionModel, needReload: Bool = true) {
    self.needReload = needReload
    self.debugSection = debugSection
  }
}

extension DebugGeneralTVC: UITableViewDataSource, UITableViewDelegate {
  var listItems: [InfoSection] {
    debugSection?.hCert.info.filter {
      !$0.isPrivate
    } ?? []
  }

  // Number of rows
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let section: InfoSection = listItems[section]
    if section.sectionItems.count == .zero {
      return 1
    }
    if !section.isExpanded {
      return 1
    }
    return section.sectionItems.count + 1
  }
  // Number of Sections
  func numberOfSections(in tableView: UITableView) -> Int {
    return listItems.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var section: InfoSection = listItems[indexPath.section]
    if section.sectionItems.count == 0 {
      let base = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath)
      guard let cell = base as? InfoCell else {
        return base
      }
      cell.draw(section)
      return cell
    } else {
      if indexPath.row == .zero {
        let base = tableView.dequeueReusableCell(withIdentifier: "InfoCellDropDown", for: indexPath)
        guard let cell = base as? InfoCellDropDown else {
          return base
        }
        cell.setupCell(with: section) { [weak self] state in
          section.isExpanded = state
          if let row = self?.debugSection?.hCert.info.firstIndex(where: {$0.header == section.header}) {
            self?.debugSection?.hCert.info[row] = section
          }
          tableView.reloadData()
        }
        return cell
      } else {
        let base = tableView.dequeueReusableCell(withIdentifier: "RuleErrorTVC", for: indexPath)
        guard let cell = base as? RuleErrorTVC else {
          return base
        }
        let item = section.sectionItems[indexPath.row - 1]
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
