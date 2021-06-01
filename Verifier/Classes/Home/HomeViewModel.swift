/*
 *  license-start
 *  
 *  Copyright (C) 2021 Ministero della Salute and all other contributors
 *  
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  
 *      http://www.apache.org/licenses/LICENSE-2.0
 *  
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
*/

//
//  HomeViewModel.swift
//  verifier-ios
//
//

import Foundation

class HomeViewModel {
    
    var lastUpdateText: Observable<String> = Observable("home.loading".localized)
    var isLoading: Observable<Bool> = Observable(true)
    var isScanEnabled: Observable<Bool> = Observable(false)
    var isVersionOutdated: Observable<Bool> = Observable(true)
    
    let connection = GatewayConnection()
    
    private func updateLastUpdateDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy, HH:mm"
        
        lastUpdateText.value = "home.lastUpdate".localized + (LocalData.sharedInstance.lastFetch.timeIntervalSince1970 > 0 ? dateFormatter.string(from: LocalData.sharedInstance.lastFetch) : "home.notAvailable".localized)
    }
    
    private func isCurrentVersionOutdated() -> Bool {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let minVersion = LocalData.sharedInstance.settings.first(where: { $0.name == "ios" && $0.type == "APP_MIN_VERSION" })?.value else {
            return false
        }
        return version.compare(minVersion, options: .numeric) == .orderedAscending
    }
    
    func loadCertificates() {
        LocalData.initialize { [weak self] in
            self?.updateLastUpdateDate()
            self?.isScanEnabled.value = true
            self?.isVersionOutdated.value = self?.isCurrentVersionOutdated()
            
            
            self?.connection.start { [weak self] error, isVersionOutdated in
                self?.isLoading.value = false
                
                if let error = error {
                    print(error)
                    return
                }
                
                self?.updateLastUpdateDate()
                
                self?.isScanEnabled.value = true
                self?.isVersionOutdated.value = isVersionOutdated
            }
        }
    }
}
