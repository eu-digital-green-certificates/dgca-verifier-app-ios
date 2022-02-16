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

typealias ProcessingCompletion = (ProcessingError?) -> Void

typealias RevocationProcessingCompletion = (Set<RevocationModel>?, Set<RevocationModel>?, ProcessingError?) -> Void
typealias PartitionProcessingCompletion = ([PartitionModel]?, ProcessingError?) -> Void
typealias MetadataProcessingCompletion = ([SliceMetaData]?, ProcessingError?) -> Void

class RevocationWorker {
    
    let revocationDataManager: RevocationManager = RevocationManager()
    let revocationService = RevocationService(baseServicePath: SharedConstants.revocationServiceBase)
    
    var loadedRevocations: [RevocationModel]?
    
    func processReloadRevocations(completion: @escaping ProcessingCompletion) {
        self.revocationService.getRevocationLists {[unowned self] revocations, etag, err in
            guard err == nil else {
                completion(.dataError(description: err!.localizedDescription))
                return
            }
            guard let revocations = revocations, /*!revocations.isEmpty,*/ let etag = etag else {
                completion(.nodata)
                return
            }
            guard revocations.isEmpty else { completion(nil); return }
            
            SecureKeyChain.save(key: "verifierETag", data: Data(etag.utf8))
            self.saveRevocationsIfNeeds(with: revocations) { loadList, updateList, err in
                let group = DispatchGroup()

                if loadList != nil {
                    group.enter()
                    self.downloadNewRevocations(revocations: loadList!) { partitions, err in
                        if let partitions = partitions {
                            group.enter()
                            self.downloadChunkMetadata(partitions: partitions) { err in
                                group.leave()
                            }
                        }
                        group.leave()
                    }
                }
                if updateList != nil {
                    group.enter()
                    self.processUpdateExistedRevocation(revocations: updateList!) { partitions, err in
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    completion(nil)
                }
            }
        }
    }
    
    private func saveRevocationsIfNeeds(with models: [RevocationModel], completion: @escaping RevocationProcessingCompletion) {
        // 8) Delete all KID entries in all tables which are not on this list.
        let currentRevocationEntries = revocationDataManager.currentRevocationEntries()
        var newlyAddedRevocations = Set<RevocationModel>()
        var revocationsToReload = Set<RevocationModel>()

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
                        revocationsToReload.insert(loadedModel)
                        
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
        
        completion(newlyAddedRevocations, revocationsToReload, nil)
    }

    private func downloadNewRevocations(revocations: Set<RevocationModel>, completion: @escaping PartitionProcessingCompletion) {
        let group = DispatchGroup()
        var partitionsForLoad = [PartitionModel]()
        for model in revocations {
            let kidForLoad = Helper.convertToBase64url(base64: model.kid)
            group.enter()
            self.revocationService.getRevocationPartitions(for: kidForLoad) { partitions, _, err in
                if err == nil, let partitions = partitions, !partitions.isEmpty {
                    self.revocationDataManager.savePartitions(kid: model.kid, models: partitions)
                    partitionsForLoad.append(contentsOf: partitions)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(partitionsForLoad, nil)
        }
    }

    private func downloadChunkMetadata(partitions: [PartitionModel], completion: @escaping ProcessingCompletion) {
        let group = DispatchGroup()

        for part in partitions {
            group.enter()
            self.revocationService.getRevocationPartitionChunks(for: part.kid, id: part.id ?? "null", cids: nil) { [unowned self] zipdata, err in
                    guard let zipdata = zipdata else {
                        group.leave()
                        return
                    }
                    
                    self.processReadZipData(kid: part.kid, zipData: zipdata)
                    group.leave()
                }
        }
        
        group.notify(queue: .main) {
             completion(nil)
        }

    }
    
    
    // MARK: - Partitions

    private func processUpdateExistedRevocation(revocations: Set<RevocationModel>, completion: @escaping PartitionProcessingCompletion) {
        let todayDate = Date()

        for revocation in revocations {
            let localPartitions = revocationDataManager.loadAllPartitions(for: revocation.kid)
            let loadedModifiedDate = Date(rfc3339DateTimeString: revocation.lastUpdated) ?? Date.distantPast
            for partition in localPartitions ?? [] {
                guard let localDate = partition.value(forKey: "lastUpdatedDate") as? Date,
                    let expiredDate = partition.value(forKey: "expired") as? Date,
                    let kid = partition.value(forKey: "kid") as? String,
                    let localChunks: NSOrderedSet = partition.value(forKey: "chunks") as? NSOrderedSet else { continue }
                let pid = partition.value(forKey: "id") as? String
                if expiredDate < todayDate {
                    revocationDataManager.deletePartition(kid: kid, id: pid ?? "null")
                }
                if localDate < loadedModifiedDate {
                    self.revocationService.getRevocationPartitionChunks(for: kid, id: pid ?? "null", cids: nil) { zipdata, err in
                        guard let zipdata = zipdata else {
                            return
                        }
                        
                        self.processReadZipData(kid: kid, zipData: zipdata)
                        // TODO update partition fields
                    }
                } else {
                    
                }

            }
        }
    }
    
    private func processReadZipData(kid: String, zipData: Data) {
        do {
            let tarData = try GzipArchive.unarchive(archive: zipData)
            let chunksInfos = try TarContainer.info(container: tarData)
            let chunksContent = try TarContainer.open(container: tarData)
            
            for ind in 0..<chunksInfos.count {
                let sliceInfo = chunksInfos[ind]
                let fileUrl = URL(fileURLWithPath: sliceInfo.name)
                var components = fileUrl.pathComponents
                let sliceHashID = components.removeLast()
                let chunkID = components.removeLast()
                let partID = components.removeLast()
                let sliceContent = chunksContent[ind]
                guard let sliceHashData = sliceContent.data else  { continue }
                
                let sliceMetadata = SliceMetaData(kid: kid, id: partID, cid: chunkID, hashID: sliceHashID, contentData: sliceHashData)
                self.revocationDataManager.saveMetadataHashes(sliceHashes: [sliceMetadata])
            }
        } catch {
            print("Data error")
        }

    }
}
