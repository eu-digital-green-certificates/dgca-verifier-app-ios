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
//  DataManagerController.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 10.04.2022.
//  
        

import UIKit
import DGCVerificationCenter
import DGCCoreLibrary

#if canImport(DCCInspection)
import DCCInspection
#endif

protocol DataManagingProtocol: AnyObject {
    func loadingInspector(_ inspector: ApplicableInspector, didFinishLoadingData value: Bool)
    func loadingInspector(_ inspector: ApplicableInspector, didFailLoadingDataWith error: Error)
}

class DataManagerController: UITableViewController {

    var applicableInspectors: [ApplicableInspector] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Verifiable Certificates".localized
        applicableInspectors = AppManager.shared.verificationCenter.applicableInspectors
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return applicableInspectors.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CertTypeCell", for: indexPath) as! CertTypeCell

        cell.applicant = applicableInspectors[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    private func showAlertCannotReload() {
        let title = "Cannot update stored data".localized
        let message = "Please check the internet connection and try again.".localized
        
        let infoAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Continue", style: .default) { action in
            self.tableView.reloadData()
        }
        infoAlertController.addAction(action)
        self.present(infoAlertController, animated: true)
    }

    private func showAlertReloadCompleted() {
        let title = "Stored data is up to date".localized
        let message = ""
        
        let infoAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Continue", style: .default) { action in
            self.tableView.reloadData()
        }
        infoAlertController.addAction(action)
        self.present(infoAlertController, animated: true)
    }

}

extension DataManagerController: DataManagingProtocol {
    func loadingInspector(_ inspector: ApplicableInspector, didFinishLoadingData value: Bool) {
        self.tableView.reloadData()
    }
    
    func loadingInspector(_ inspector: ApplicableInspector, didFailLoadingDataWith error: Error) {
        self.tableView.reloadData()
    }

}
