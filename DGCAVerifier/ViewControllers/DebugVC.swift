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
//  DebugVC.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 02.09.2021.
//  
        

import UIKit
import SwiftDGC
import SwiftyJSON

class DebugVC: UIViewController {

  private enum Constants {
    static let fontSize: CGFloat = 16
  }
  
  @IBOutlet weak var debugSwitcher: UISwitch!
  @IBOutlet weak var level1: UILabel!
  @IBOutlet weak var level2: UILabel!
  @IBOutlet weak var level3: UILabel!
  @IBOutlet weak var tableView: UITableView!
  
  private var countryList = [CountryModel]()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.dataSource = self
    tableView.delegate = self
    
    self.countryList = CountryDataStorage.sharedInstance.countryCodes.sorted(by: { model1, model2 in
      model1.name < model2.name
    })
    self.tableView.reloadData()
    debugSwitcher.isOn = DebugManager.sharedInstance.isDebugMode
    
    var tap = UITapGestureRecognizer(target: self, action: #selector(DebugVC.tapOnLabel1))
    level1.isUserInteractionEnabled = true
    level1.addGestureRecognizer(tap)

    tap = UITapGestureRecognizer(target: self, action: #selector(DebugVC.tapOnLabel2))
    level2.isUserInteractionEnabled = true
    level2.addGestureRecognizer(tap)

    tap = UITapGestureRecognizer(target: self, action: #selector(DebugVC.tapOnLabel3))
    level3.isUserInteractionEnabled = true
    level3.addGestureRecognizer(tap)
    
    setLabelsColor()
  }
  @IBAction func debugSwitchAction(_ sender: Any) {
    DebugManager.sharedInstance.isDebugMode = debugSwitcher.isOn
  }
  @IBAction func tapOnLabel1(sender: UITapGestureRecognizer) {
    print("tap working")
    DebugManager.sharedInstance.debugLevel = .level1
    setLabelsColor()
  }
  @IBAction func tapOnLabel2(sender: UITapGestureRecognizer) {
    print("tap working")
    DebugManager.sharedInstance.debugLevel = .level2
    setLabelsColor()
  }
  @IBAction func tapOnLabel3(sender: UITapGestureRecognizer) {
    print("tap working")
    DebugManager.sharedInstance.debugLevel = .level3
    setLabelsColor()
  }
  func setLabelsColor() {
    switch DebugManager.sharedInstance.debugLevel {
    case .level1:
      level1.textColor = .blue
      level2.textColor = .black
      level3.textColor = .black
      level1.font = UIFont.boldSystemFont(ofSize: Constants.fontSize)
      level2.font = UIFont.systemFont(ofSize: Constants.fontSize)
      level3.font = UIFont.systemFont(ofSize: Constants.fontSize)
    case .level2:
      level1.textColor = .black
      level2.textColor = .blue
      level3.textColor = .black
      level1.font = UIFont.systemFont(ofSize: Constants.fontSize)
      level2.font = UIFont.boldSystemFont(ofSize: Constants.fontSize)
      level3.font = UIFont.systemFont(ofSize: Constants.fontSize)
    case .level3:
      level1.textColor = .black
      level2.textColor = .black
      level3.textColor = .blue
      level1.font = UIFont.systemFont(ofSize: Constants.fontSize)
      level2.font = UIFont.systemFont(ofSize: Constants.fontSize)
      level3.font = UIFont.boldSystemFont(ofSize: Constants.fontSize)
    }
  }
  
  @IBAction func doneButtonAction(_ sender: Any) {
    dismiss(animated: true)
  }
}

extension DebugVC: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    countryList.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let base = tableView.dequeueReusableCell(withIdentifier: "DebugTVC", for: indexPath)
    let countryModel = countryList[indexPath.row]
    guard let cell = base as? DebugTVC else {
      return base
    }
    cell.setCountry(countryModel: countryModel)
    cell.selectionStyle = .none
    if countryModel.debugModeEnabled {
      cell.accessoryType = .checkmark
    } else {
      cell.accessoryType = .none
    }
    return cell
  }
}

extension DebugVC: UITableViewDelegate{
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let countryModel = countryList[indexPath.row]
    countryModel.debugModeEnabled = !countryModel.debugModeEnabled
    CountryDataStorage.sharedInstance.update(country: countryModel)
    if let cell = tableView.cellForRow(at: indexPath) {
      if countryModel.debugModeEnabled {
        cell.accessoryType = .checkmark
      } else {
        cell.accessoryType = .none
      }
    }
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60
  }
}
