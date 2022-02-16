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
import SWCompression


public enum ProcessingError: Error {
    case nodata
    case dataError(description: String)
    case dataBaseError(error: NSError)
}

typealias ProcessingCompletion = ([PartitionModel]?, ProcessingError?) -> Void

class RevocationWorker {
    
    let revocationDataManager: RevocationManager = RevocationManager()
    let revocationService = RevocationService(baseServicePath: SharedConstants.revocationServiceBase)
    
    var loadedRevocations: [RevocationModel]?
    
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
            let loadingRevocationsSet = self.saveRevocationsIfNeeds(with: revocations)
            
            let group = DispatchGroup()
            var partitionsList = [PartitionModel]()
            for model in loadingRevocationsSet {
                let kidForLoad = Helper.convertToBase64url(base64: model.kid)
                group.enter()
                self.revocationService.getRevocationPartitions(forKID: kidForLoad) { partitions, _, err in
                    if err == nil, let partitions = partitions, !partitions.isEmpty {
                        self.revocationDataManager.savePartitions(kid: model.kid, models: partitions)
                        partitionsList.append(contentsOf: partitions)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion(partitionsList, .nodata)
            }
        }
    }
    
    func processLoadMetaData(partitions: [PartitionModel], completion: @escaping ProcessingCompletion) {
        let group = DispatchGroup()

        for part in partitions {
            if let id = part.id {
                group.enter()
                self.revocationService.getRevocationPartitionChunks(forKID: part.kid, id: id, cids: nil) { zipdata, _, err in
                    guard let zipdata = zipdata else {
                        group.leave()
                        return
                    }
                    
                    do {
                        let tarData = try GzipArchive.unarchive(archive: zipdata)
                        let chunksInfos = try TarContainer.info(container: tarData)
                        
                        for chunkInfo in chunksInfos {
                            let fileUrl = URL(fileURLWithPath: chunkInfo.name)
                            let hash = fileUrl.lastPathComponent
                            
                            // TODO: create slice model
                        }
                    } catch {
                        
                    }
                    
                    group.leave()
                }
            }
        }
    }
    
    private func saveRevocationsIfNeeds(with models: [RevocationModel]) -> Set<RevocationModel> {
        // 8) Delete all KID entries in all tables which are not on this list.
        let currentRevocationEntries = revocationDataManager.currentRevocationEntries()
        var newlyAddedRevocations = Set<RevocationModel>()
        
        if !currentRevocationEntries.isEmpty {
            for entry in currentRevocationEntries {
                let localKid = entry.kid
                let localMode = entry.mode
                let localModifiedDate = entry.lastUpdated
                let localExpiredDate = entry.expires
                let todayDate = Date()

                if let loadedModel = models.filter({ Helper.convertToBase64url(base64: $0.kid) == localKid }).first {
                    // 9) Check if “Mode” was changed. If yes, delete all associated entries with the KID.
                    let loadedModifiedDate = Date(rfc3339DateTimeString: loadedModel.lastUpdated) ?? Date.distantPast
                    
                    if loadedModel.mode != localMode {
                        self.revocationDataManager.removeRevocation(localKid)
                        self.revocationDataManager.saveRevocations([loadedModel])
                        newlyAddedRevocations.insert(loadedModel)
                        
                    } else if localModifiedDate < loadedModifiedDate {
                        self.processUpdateExistedRevocation(kid: localKid, loadedDate: loadedModifiedDate)
                        
                    } else if localExpiredDate < todayDate {
                        self.revocationDataManager.removeRevocation(localKid)
                    }
                } else {
                    self.revocationDataManager.removeRevocation(localKid)
                }
            }
        }
        
        for model in models {
            if currentRevocationEntries.filter({ $0.0 == Helper.convertToBase64url(base64:model.kid) }).isEmpty {
                self.revocationDataManager.saveRevocations([model])
                newlyAddedRevocations.insert(model)
            }
        }
        return newlyAddedRevocations
    }
    
    // MARK: - Partitions

    private func processUpdateExistedRevocation(kid: String, loadedDate: Date) {
        let localPartitions = revocationDataManager.loadAllPartitions(forKID: kid)
        let todayDate = Date()
        for partition in localPartitions ?? [] {
            guard let localDate = partition.value(forKey: "lastUpdatedDate") as? Date,
                  let expiredDate = partition.value(forKey: "expired") as? Date,
                  let kid = partition.value(forKey: "kid") as? String,
                  let pid = partition.value(forKey: "id") as? String,
                let localChunks: NSOrderedSet = partition.value(forKey: "chunks") as? NSOrderedSet else { continue }
            
            if expiredDate < todayDate {
                revocationDataManager.deletePartition(id: pid)
            }
            
            if localDate < loadedDate {
                self.revocationService.getRevocationPartitionChunks(forKID: kid, id: pid, cids: nil) { zipdata, _, err in
                    ()
                }

            } else {
                for chunk in localChunks {
                    
                }
            }
        }

    }
}
