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
//  RevocationWorker.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 10.02.2022.
//  
        

import UIKit
import SwiftDGC

public enum ProcessingError: Error {
    case nodata
    case dataError
    case dataBaseError(error: NSError)
}

typealias ProcessingCompletion = (ProcessingError?) -> Void

class RevocationWorker {
    
    let revocationManager: RevocationManager = RevocationManager()
    let revocationService = RevocationService(baseServicePath: SharedConstants.revocationServiceBase)
    
    var loadedRevocations: [RevocationModel]?
    
    func processReloadRevocations(completion: @escaping ProcessingCompletion) {
        self.revocationService.loadAllRevocations {[unowned self] revocations, etag, err in
            self.removeOutdatedRevocations()
            self.processAddRevocation(models: revocations, eTag: etag)
        }
    }
    
    private func removeOutdatedRevocations() {
        guard let revocationModels = loadedRevocations else { return }
        
        if let currentKIDs = revocationManager.currentRevocationKIDs() {
            for kid in currentKIDs {
                if !revocationModels.filter({ $0.kid == kid }).isEmpty {
                    self.revocationManager.removeRevocations(kid: kid)
                } else {
                    
                }
            }
        }
    }
    
    private func processAddRevocation(models: [RevocationModel]?, eTag: String?) {
//        guard let models = models, let eTag = eTag else {
//            completion(ProcessingError.nodata)
//            return
//        }
        //-------------------
        let str = """
            [{
                       "kid":"9cWXDDA52FQ=",
                       "mode":"POINT",
                       "hashType":["SIGNATURE","UCI","COUNTRYCODEUCI"],
                       "expires":"2010-01-01T12:00:00+01:00",
                       "lastUpdated":"2009-01-01T12:00:00+01:00"
            },
            {
                       "kid":"8cWXDDA52FQ=",
                       "mode":"POINT",
                       "hashType":["SIGNATURE","UCI","COUNTRYCODEUCI"],
                       "expires":"2010-01-01T12:00:00+01:00",
                       "lastUpdated":"2009-01-01T12:00:00+01:00"
            }]
        """
        let data = Data(str.utf8)
        let decodedModels: [RevocationModel] = try! JSONDecoder().decode([RevocationModel].self, from: data)
        //-------------------
        self.loadedRevocations = decodedModels
        
        if let currentKIDs = revocationManager.currentRevocationKIDs() {
            var newAddedRevocations = [RevocationModel]()
            for model in decodedModels {
                if !currentKIDs.filter({ $0 == model.kid }).isEmpty {
                    self.revocationManager.saveRevocations(models: [model])
                    newAddedRevocations.append(model)
                }
            }
        }
    }
}
