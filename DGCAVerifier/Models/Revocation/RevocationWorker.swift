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
    case dataError(description: String)
    case dataBaseError(error: NSError)
}

typealias ProcessingCompletion = ([String]?, ProcessingError?) -> Void

class RevocationWorker {
    
    let revocationDataManager: RevocationManager = RevocationManager()
    let revocationService = RevocationService(baseServicePath: SharedConstants.revocationServiceBase)
    
    var loadedRevocations: [RevocationModel]?
    var eTag: String? {
        didSet {
            ()
        }
    }
    
    func processReloadRevocations(completion: @escaping ProcessingCompletion) {
        self.revocationService.getRevocationLists {[unowned self] revocations, etag, err in
            guard err == nil else {
                completion(nil, .dataError(description: err!.localizedDescription))
                return
            }
            guard let revocations = revocations, /*!revocations.isEmpty,*/ let etag = etag else {
                completion(nil, .nodata)
                return
            }
            SecureKeyChain.save(key: "verifierETag", data: Data(etag.utf8))
            self.loadedRevocations = revocations
            let loadingRevocationsSet = self.saveRevocationsIfNeeds(with: revocations)
            
            let group = DispatchGroup()
            var partitionIDList = [String]()
            for model in loadingRevocationsSet {
                let kidForLoad = Helper.convertToBase64url(base64: model.kid)
                group.enter()
                self.revocationService.getRevocationPartitions(for: kidForLoad) { partitions, _, err in
                    if err == nil, let partitions = partitions, !partitions.isEmpty {
                        let idList = self.revocationDataManager.savePartitions(kid: model.kid, models: partitions)
                        partitionIDList.append(contentsOf: idList)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion(partitionIDList, .nodata)
            }
        }
    }
    
    func processLoadMetaData(partitions: [String], completion: @escaping ProcessingCompletion) {
        let group = DispatchGroup()

        for partID in partitions {
            
        }
    }
    
    private func saveRevocationsIfNeeds(with models: [RevocationModel]) -> Set<RevocationModel> {
        // 8) Delete all KID entries in all tables which are not on this list.
        let currentRevocationEntries = revocationDataManager.currentRevocationEntries()
        var newlyAddedRevocations = Set<RevocationModel>()

        if !currentRevocationEntries.isEmpty {
            for entry in currentRevocationEntries {
                let entryKid = entry.kid
                let entryMode = entry.mode
                let modifiedDate = entry.lastUpdated
                let expiredDate = entry.expires
                let todayDate = Date()
                if let revocationModel = models.filter({ Helper.convertToBase64url(base64: $0.kid) == entryKid }).first {
                    // 9) Check if “Mode” was changed. If yes, delete all associated entries with the KID.
                    let internalModelKID = Helper.convertToBase64url(base64: revocationModel.kid)
                    if revocationModel.mode != entryMode {
                        self.revocationDataManager.removeRevocations(kid: internalModelKID)
                        self.revocationDataManager.saveRevocations(models: [revocationModel])
                        newlyAddedRevocations.insert(revocationModel)
                    } else if modifiedDate < todayDate {
                        self.revocationDataManager.removeRevocations(kid: internalModelKID)
                        self.revocationDataManager.saveRevocations(models: [revocationModel])
                        newlyAddedRevocations.insert(revocationModel)
                        
                    } else if expiredDate < todayDate {
                        self.revocationDataManager.removeRevocations(kid: revocationModel.kid)
                    }
                } else {
                    self.revocationDataManager.removeRevocations(kid: entryKid)
                }
            }
        }
        
        for model in models {
            if currentRevocationEntries.filter({ $0.0 == Helper.convertToBase64url(base64:model.kid) }).isEmpty {
                self.revocationDataManager.saveRevocations(models: [model])
                newlyAddedRevocations.insert(model)
            }
        }
        return newlyAddedRevocations
    }
    
    private func processAddRevocation(models: [RevocationModel]) {
//        guard let models = models, let eTag = eTag else {
//            completion(ProcessingError.nodata)
//            return
//        }
        //-------------------
        let str = """
            [{
                       "kid":"9cWXDDA52FQ=",
                       "mode":"POINT",
                       "hashTypes":["SIGNATURE","UCI","COUNTRYCODEUCI"],
                       "expires":"2010-01-01T12:00:00+01:00",
                       "lastUpdated":"2009-01-01T12:00:00+01:00"
            },
            {
                       "kid":"8cWXDDA52FQ=",
                       "mode":"POINT",
                       "hashTypes":["SIGNATURE","UCI","COUNTRYCODEUCI"],
                       "expires":"2010-01-01T12:00:00+01:00",
                       "lastUpdated":"2009-01-01T12:00:00+01:00"
            }]
        """
        let data = Data(str.utf8)
        let decodedModels: [RevocationModel] = try! JSONDecoder().decode([RevocationModel].self, from: data)
        //-------------------
        
    }
    
    // MARK: - Partitions

    
}
