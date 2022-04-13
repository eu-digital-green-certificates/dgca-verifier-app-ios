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
//  DebugController.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 02.09.2021.
//  
        

import UIKit
import DGCCoreLibrary
import DCCInspection

protocol DebugControllerDelegate: AnyObject {
    func debugControllerDidSelect(isDebugMode: Bool, level: DebugLevel)
}

class DebugController: UIViewController {

    private enum Constants {
      static let fontSize: CGFloat = 16
      static let selectedFontSize: CGFloat = 18
    }

    @IBOutlet weak var debugSwitcher: UISwitch!
    @IBOutlet weak var level1: UILabel!
    @IBOutlet weak var level2: UILabel!
    @IBOutlet weak var level3: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet fileprivate weak var selectCountriesLabel: UILabel!
    @IBOutlet fileprivate weak var debugModeLabel: UILabel!

    private var countryList = [CountryModel]()
    weak var delegate: DebugControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        self.countryList = DCCDataCenter.countryCodes.sorted(by: { $0.name < $1.name })
        self.tableView.reloadData()
        debugSwitcher.isOn = DebugManager.sharedInstance.isDebugMode
        
        var tap = UITapGestureRecognizer(target: self, action: #selector(tapOnLabel1))
        level1.isUserInteractionEnabled = true
        level1.addGestureRecognizer(tap)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(tapOnLabel2))
        level2.isUserInteractionEnabled = true
        level2.addGestureRecognizer(tap)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(tapOnLabel3))
        level3.isUserInteractionEnabled = true
        level3.addGestureRecognizer(tap)
        
        setLabelsColor()
        level1.text = "Level 1".localized
        level2.text = "Level 2".localized
        level3.text = "Level 3".localized
        selectCountriesLabel.text = "Select Countries".localized
        debugModeLabel.text = "Debug mode".localized
    }
    
    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      delegate?.debugControllerDidSelect(isDebugMode: DebugManager.sharedInstance.isDebugMode,
          level: DebugManager.sharedInstance.debugLevel)
    }

    @IBAction func debugSwitchAction(_ sender: Any) {
        let isValue = debugSwitcher.isOn
        DebugManager.sharedInstance.isDebugMode = isValue
        setLabelsColor()
        tableView.reloadData()
    }
    
    @IBAction func tapOnLabel1(sender: UITapGestureRecognizer) {
        DGCLogger.logInfo("tapOnLabel1 working")
        DebugManager.sharedInstance.debugLevel = .level1
        setLabelsColor()
    }
    
    @IBAction func tapOnLabel2(sender: UITapGestureRecognizer) {
        DGCLogger.logInfo("tapOnLabel2 working")
        DebugManager.sharedInstance.debugLevel = .level2
        setLabelsColor()
    }
    
    @IBAction func tapOnLabel3(sender: UITapGestureRecognizer) {
        DGCLogger.logInfo("tapOnLabel3 working")
        DebugManager.sharedInstance.debugLevel = .level3
        setLabelsColor()
    }
    
    func setLabelsColor() {
      if DebugManager.sharedInstance.isDebugMode {
          switch DebugManager.sharedInstance.debugLevel {
          case .level1:
            level1.textColor = .verifierBlue
            level2.textColor = .charcoalGrey
            level3.textColor = .charcoalGrey
            level1.font = UIFont.boldSystemFont(ofSize: Constants.selectedFontSize)
            level2.font = UIFont.systemFont(ofSize: Constants.fontSize)
            level3.font = UIFont.systemFont(ofSize: Constants.fontSize)
          case .level2:
            level1.textColor = .charcoalGrey
            level2.textColor = .verifierBlue
            level3.textColor = .charcoalGrey
            level1.font = UIFont.systemFont(ofSize: Constants.fontSize)
            level2.font = UIFont.boldSystemFont(ofSize: Constants.selectedFontSize)
            level3.font = UIFont.systemFont(ofSize: Constants.fontSize)
          case .level3:
            level1.textColor = .charcoalGrey
            level2.textColor = .charcoalGrey
            level3.textColor = .verifierBlue
            level1.font = UIFont.systemFont(ofSize: Constants.fontSize)
            level2.font = UIFont.systemFont(ofSize: Constants.fontSize)
            level3.font = UIFont.boldSystemFont(ofSize: Constants.selectedFontSize)
          }
        } else {
            level1.textColor = .lightGray
            level2.textColor = .lightGray
            level3.textColor = .lightGray
            level1.font = UIFont.systemFont(ofSize: Constants.fontSize)
            level2.font = UIFont.systemFont(ofSize: Constants.fontSize)
            level3.font = UIFont.systemFont(ofSize: Constants.fontSize)
        }
    }
    
    @IBAction func doneButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension DebugController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if DebugManager.sharedInstance.isDebugMode {
            return countryList.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DebugCountryCell", for: indexPath) as?
            DebugCountryCell else { return UITableViewCell() }
        
        let countryModel = countryList[indexPath.row]
        cell.setCountry(countryModel: countryModel)
        cell.selectionStyle = .none
        cell.accessoryType = countryModel.debugModeEnabled ? .checkmark : .none

        return cell
    }
}

extension DebugController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let countryModel = countryList[indexPath.row]
        countryModel.debugModeEnabled = !countryModel.debugModeEnabled
        DCCDataCenter.localDataManager.update(country: countryModel)
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = countryModel.debugModeEnabled ? .checkmark : .none
        }
        tableView.reloadData()
    }
}
