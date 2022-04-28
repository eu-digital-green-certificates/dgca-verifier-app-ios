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
//  CountryListController.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 13.04.2022.
//  
        

import UIKit
import DGCVerificationCenter
import DGCCoreLibrary

class CountryCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    private var country: CountryModel? {
        didSet {
            setupView()
        }
    }
    
    func setupView() {
        guard let nameLabel = nameLabel, let country = country else {
            nameLabel.text = ""
            return
        }
        nameLabel.text = country.name
    }
    
    func setCountry(countryModel: CountryModel) {
        country = countryModel
    }
}

class CountryListController: UITableViewController {

    private var countryList: [CountryModel] = []
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
        title = "DCC Country Codes".localized
        self.countryList = DGCVerificationCenter.countryCodes
        self.tableView.reloadData()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countryList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath) as?
            CountryCell else { return UITableViewCell() }
        
        let countryModel = countryList[indexPath.row]
        cell.setCountry(countryModel: countryModel)
        cell.accessoryType = selectedCounty?.code == countryModel.code ? .checkmark : .none
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCounty = countryList[indexPath.row]
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark 
        }
        tableView.reloadData()
    }
}
