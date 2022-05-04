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
//  SettingsController.swift
//  DGCAVerifier
//
//  Created by Yannick Spreen on 4/19/21.
//

import UIKit
import DGCVerificationCenter
import DGCCoreLibrary

#if canImport(DCCInspection)
import DCCInspection
#endif

class SettingsController: UITableViewController, DebugControllerDelegate {
    private enum Constants {
        static let licenseSegueID = "LicensesVC"
        static let debugSegueID = "DebugVC"
        static let showDataManager = "showDataManager"
        static let showCountryList = "showCountryList"
    }
    
    weak var delegate: DebugControllerDelegate?
    weak var dismissDelegate: DismissControllerDelegate?
    var isNavigating = false
    var isDCCAdded = false
    
    @IBOutlet fileprivate weak var appNameLabel: UILabel!
    @IBOutlet fileprivate weak var licensesLabelName: UILabel!
    @IBOutlet fileprivate weak var privacyLabelName: UILabel!
    @IBOutlet fileprivate weak var debugLabelName: UILabel!
    @IBOutlet fileprivate weak var debugLabel: UILabel!
    @IBOutlet fileprivate weak var versionLabel: UILabel!
    @IBOutlet fileprivate weak var manageDataLabel: UILabel!
    @IBOutlet fileprivate weak var countryTitleLabel: UILabel!
    @IBOutlet fileprivate weak var selectedCountryLabel: UILabel!

    private var selectedCounty: CountryModel? {
        set {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(newValue)
                UserDefaults.standard.set(data, forKey: AppManager.userDefaultsCountryKey)
            } catch {
                DGCLogger.logError(error)
            }
        }
        get {
            if let data = UserDefaults.standard.data(forKey: AppManager.userDefaultsCountryKey) {
                let decoder = JSONDecoder()
                do {
                    let object = try decoder.decode(CountryModel.self, from: data)
                    return object
                } catch {
                    DGCLogger.logError(error)
                }
            }
            return nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        var filterType: String = ""
        var colaboratorsType = ""
        selectedCountryLabel.text = ""
        selectedCountryLabel.text = ""
        
        #if canImport(DCCInspection)
            isDCCAdded = true
            filterType = sliceType.rawValue.uppercased().contains("BLOOM") ? "BLOOM" : "HASH"
            let link = DCCDataCenter.localDataManager.versionedConfig["context"]["url"].rawString()
            colaboratorsType = link!.contains("acc2") ? "ACC2" : "TST"
            selectedCountryLabel.text = selectedCounty?.name
        #else
            countryTitleLabel.textColor = .gray
        #endif
        
        appNameLabel.text = (Bundle.main.infoDictionary?["CFBundleDisplayName"] as! String) +
            " (" + filterType + ", " + colaboratorsType + ")"
        
        debugLabelName.text = "Debug mode".localized
        licensesLabelName.text = "Licenses".localized
        privacyLabelName.text = "Privacy Information".localized
        manageDataLabel.text = "Manage Data".localized
        versionLabel.text = DGCVerificationCenter.appVersion
        countryTitleLabel.text = "DCC Country Code"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isNavigating = false
        updateInterface()
        #if canImport(DCCInspection)
            selectedCountryLabel.text = selectedCounty?.name
        #endif
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !isNavigating  {
            delegate?.debugControllerDidSelect(isDebugMode: DebugManager.sharedInstance.isDebugMode,
              level: DebugManager.sharedInstance.debugLevel)
        }
    }
    
    private func updateInterface() {
        if !DebugManager.sharedInstance.isDebugMode {
            debugLabel.text = "Disabled".localized
        } else {
            switch DebugManager.sharedInstance.debugLevel {
            case .level1:
                debugLabel.text = "Level 1".localized
            case .level2:
                debugLabel.text = "Level 2".localized
            case .level3:
                debugLabel.text = "Level 3".localized
             }
        }
    }
    
    func debugControllerDidSelect(isDebugMode: Bool, level: DebugLevel) {
        updateInterface()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.section {
        case 1:
            if indexPath.row == 0 {
                openPrivacyDoc()
            } else if indexPath.row == 1 {
                openLicenses()
            } else if indexPath.row == 2 {
                openDebugSettings()
            }
            
        case 2:
            showDataManager()
            
        case 3:
            showCountryList()
            
        default:
            break
        }
    }
    
    private func openPrivacyDoc() {
        #if canImport(DCCInspection)
            let link = DCCDataCenter.localDataManager.versionedConfig["privacyUrl"].string ?? ""
            openUrl(link)
        #endif
    }
    
    private func openEuCertDoc() {
        let link = SharedLinks.linkToOopenEuCertDoc
        openUrl(link)
    }
    
    private func openGitHubSource() {
        let link = SharedLinks.linkToOpenGitHubSource
        openUrl(link)
    }
    
    private func openDebugSettings() {
        performSegue(withIdentifier: Constants.debugSegueID, sender: self)
    }
    
    private func openLicenses() {
        isNavigating = true
        performSegue(withIdentifier: Constants.licenseSegueID, sender: self)
    }
    
    private func openUrl(_ string: String!) {
        if let url = URL(string: string) {
            UIApplication.shared.open(url)
        }
    }
    
    private func showDataManager() {
        performSegue(withIdentifier: Constants.showDataManager, sender: self)
    }
    
    private func showCountryList() {
        if isDCCAdded {
            performSegue(withIdentifier: Constants.showCountryList, sender: self)
        }
    }
    
    @IBAction func dismissAction() {
        dismiss(animated: true, completion: nil)
        dismissDelegate?.userDidDissmis(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case Constants.debugSegueID:
            if let destinationController = segue.destination as? DebugController {
                destinationController.delegate = self
            }
        default:
            break
        }
    }
}
