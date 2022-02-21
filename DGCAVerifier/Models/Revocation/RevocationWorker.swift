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
        

import Foundation
import SwiftDGC
import SWCompression
import CoreData


typealias ProcessingCompletion = (RevocationError?) -> Void

typealias RevocationProcessingCompletion = (Set<RevocationModel>?, Set<RevocationModel>?, RevocationError?) -> Void
typealias PartitionProcessingCompletion = ([PartitionModel]?, RevocationError?) -> Void
typealias MetadataProcessingCompletion = ([SliceMetaData]?, RevocationError?) -> Void

class RevocationWorker {
    
    let revocationDataManager: RevocationManager = RevocationManager()
    let revocationService = RevocationService(baseServicePath: SharedConstants.revocationServiceBase)
    var loadedRevocations: [RevocationModel]?
    
    // MARK: - Work with Revocations

    func processReloadRevocations(completion: @escaping ProcessingCompletion) {
        let center = NotificationCenter.default
        
        self.revocationService.getRevocationLists {[unowned self] revocations, etag, err in
            guard err == nil else {
                completion(.network(reason: err!.localizedDescription))
                return
            }
            guard let revocations = revocations, !revocations.isEmpty, let etag = etag else {
                completion(.nodata)
                return
            }
            
            SecureKeyChain.save(key: "verifierETag", data: Data(etag.utf8))
            self.saveRevocationsIfNeeds(with: revocations) { loadPartList, updatePartList, err in
                let group = DispatchGroup()

                if let loadList = loadPartList, !loadList.isEmpty {
                    group.enter()
                    self.downloadNewRevocations(revocations: loadList) { partitions, err in
                        guard err == nil else {
                            completion(err!)
                            return
                        }

                        if let partitions = partitions, !partitions.isEmpty {
                            center.post(name: Notification.Name("LoadingRevocationsNotificationName"),
                                object: nil, userInfo: ["name": "Preparation of database on revocation of certificates".localized])
                            group.enter()
                            self.downloadChunkMetadata(partitions: partitions) { err in
                                guard err == nil else {
                                    completion(err!)
                                    return
                                }

                                group.leave()
                            }
                        }
                        group.leave()
                    }
                }
                if let updateList = updatePartList, !updateList.isEmpty {
                    group.enter()
                    self.downloadNewRevocationsForUpdate(revocations: updateList) { partitions, err in
                        guard err == nil else {
                            completion(err!)
                            return
                        }

                        if let partitions = partitions {
                            center.post(name: Notification.Name("LoadingRevocationsNotificationName"), object: nil,
                                userInfo: ["name": "Loading the certificate metadata".localized])
                            group.enter()
                            self.updateExistedPartitions(partitions) { err in
                                group.leave()
                            }
                        }
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
        var currentRevocations: [Revocation]?
        if Thread.isMainThread {
            currentRevocations = self.revocationDataManager.currentRevocations()
        } else {
            DispatchQueue.main.sync {
                currentRevocations = self.revocationDataManager.currentRevocations()
            }
        }
    
        var newlyAddedRevocations = Set<RevocationModel>()
        var revocationsToReload = Set<RevocationModel>()

        if let currentRevocations = currentRevocations, !currentRevocations.isEmpty {
            for revocationObject in currentRevocations {
                guard
                    let localKid = revocationObject.value(forKey: "kid") as? String,
                    let localMode = revocationObject.value(forKey: "mode") as? String,
                    let localModifiedDate = revocationObject.value(forKey: "lastUpdated") as? Date,
                    let localExpiredDate = revocationObject.value(forKey: "expires") as? Date
                else { continue }
                let todayDate = Date()

                if let loadedModel = models.filter({ Helper.convertToBase64url(base64: $0.kid) == localKid }).first {
                    // 9) Check if “Mode” was changed. If yes, delete all associated entries with the KID.
                    let loadedModifiedDate = Date(rfc3339DateTimeString: loadedModel.lastUpdated) ?? Date.distantPast
                    
                    if loadedModel.mode != localMode {
                        DispatchQueue.main.async {
                            self.revocationDataManager.removeRevocation(kid: localKid)
                            self.revocationDataManager.saveRevocations([loadedModel])
                        }
                        newlyAddedRevocations.insert(loadedModel)
                        
                    } else if localModifiedDate < loadedModifiedDate {
                        revocationsToReload.insert(loadedModel)
                        
                    } else if localExpiredDate < todayDate {
                        DispatchQueue.main.async {
                            self.revocationDataManager.removeRevocation(kid: localKid)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.revocationDataManager.removeRevocation(kid: localKid)
                    }
                }
            }
        }

        for model in models {
            if currentRevocations?.filter({ ($0.value(forKey: "kid") as? String) == Helper.convertToBase64url(base64:model.kid) }).isEmpty ?? false {
                DispatchQueue.main.async {
                    self.revocationDataManager.saveRevocations([model])
                }
                newlyAddedRevocations.insert(model)
            }
        }
        completion(newlyAddedRevocations, revocationsToReload, nil)
    }

    private func downloadNewRevocations(revocations: Set<RevocationModel>, completion: @escaping PartitionProcessingCompletion) {
        let center = NotificationCenter.default
        let group = DispatchGroup()
        var partitionsForLoad = [PartitionModel]()
        var index: Float = 1.0
        for model in revocations {
            let kidForLoad = Helper.convertToBase64url(base64: model.kid)
            group.enter()
            self.revocationService.getRevocationPartitions(for: kidForLoad) { partitions, _, err in
                guard err == nil else {
                    completion(nil, .network(reason: err!.localizedDescription))
                    return
                }

                let progress: Float = index/Float(revocations.count)
                center.post(name: Notification.Name("LoadingRevocationsNotificationName"), object: nil, userInfo: ["name" : "Downloading the certificate revocations database".localized, "progress" : progress] )
                index += 1.0
                if err == nil, let partitions = partitions, !partitions.isEmpty {
                    DispatchQueue.main.async {
                        self.revocationDataManager.savePartitions(kid: model.kid, models: partitions)
                    }
                    partitionsForLoad.append(contentsOf: partitions)
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(partitionsForLoad, nil)
        }
    }

    private func downloadNewRevocationsForUpdate(revocations: Set<RevocationModel>, completion: @escaping PartitionProcessingCompletion) {
        let center = NotificationCenter.default
        let group = DispatchGroup()
        var partitionsForUpdate = [PartitionModel]()
        var index: Float = 1.0
        
        for model in revocations {
            let kidForLoad = Helper.convertToBase64url(base64: model.kid)
            group.enter()
            self.revocationService.getRevocationPartitions(for: kidForLoad) { partitions, _, err in
                guard err == nil else {
                    completion(nil, err!)
                    return
                }

                let progress: Float = index/Float(revocations.count)
                center.post(name: Notification.Name("LoadingRevocationsNotificationName"), object: nil, userInfo: ["name" : "Updating the certificate revocations database".localized, "progress" : progress] )
                index += 1.0
                print(progress)
                if err == nil, let partitions = partitions, !partitions.isEmpty {
                    partitionsForUpdate.append(contentsOf: partitions)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(partitionsForUpdate, nil)
        }
    }
    
    // MARK: - download Chunks

    private func downloadChunkMetadata(partitions: [PartitionModel], completion: @escaping ProcessingCompletion) {
        let group = DispatchGroup()
        var index: Float = 1.0
        let center = NotificationCenter.default

        for part in partitions {
            group.enter()
            let kidConverted = Helper.convertToBase64url(base64: part.kid)
            self.revocationService.getRevocationPartitionChunks(for:kidConverted, id: part.id ?? "null", cids: nil) { [unowned self] zipdata, err in
                guard err == nil else {
                    completion(err!)
                    return
                }

                let progress: Float = index/Float(partitions.count)
                
                center.post(name: Notification.Name("LoadingRevocationsNotificationName".localized), object: nil, userInfo: ["name" : "Downloading the certificate revocations metadata".localized, "progress" : progress] )
                index += 1.0
                guard let zipdata = zipdata else {
                    completion(RevocationError.nodata)
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
    
    
    // MARK: - update Partitions

    private func updateExistedPartitions(_ partitions: [PartitionModel], completion: @escaping ProcessingCompletion) {
        let todayDate = Date()
        var index: Float = 1.0
        let center = NotificationCenter.default
        let group = DispatchGroup()

        for partition in partitions {
            var localPartitions: [Partition]?
            if Thread.isMainThread {
                localPartitions = revocationDataManager.loadAllPartitions(for: partition.kid)
            } else {
                DispatchQueue.main.sync {
                    localPartitions = self.revocationDataManager.loadAllPartitions(for: partition.kid)
                }
            }
            let loadedModifiedDate = Date(rfc3339DateTimeString: partition.lastUpdated) ?? Date.distantPast
            
            let progress: Float = index/Float(partitions.count)
            center.post(name: Notification.Name("LoadingRevocationsNotificationName".localized), object: nil, userInfo: ["name" : "Updating the certificate revocations metadata".localized, "progress" : progress] )
            index += 1.0
            
            if let localPartition = localPartitions?.filter({ $0.value(forKey: "kid") as! String == partition.kid &&
                $0.value(forKey: "id") as? String == partition.id}).first {
                guard let localDate = localPartition.value(forKey: "lastUpdatedDate") as? Date,
                    let expiredDate = localPartition.value(forKey: "expired") as? Date,
                    let kid = localPartition.value(forKey: "kid") as? String,
                    let pid = localPartition.value(forKey: "id") as? String,
                    let localChunks: NSOrderedSet = localPartition.value(forKey: "chunks") as? NSOrderedSet else { continue }

                if expiredDate < todayDate {
                    DispatchQueue.main.async {
                        self.revocationDataManager.deletePartition(kid: kid, id: pid)
                    }
                }
                if localDate < loadedModifiedDate {
                    group.enter()
                    self.revocationService.getRevocationPartitionChunks(for: kid, id: pid, cids: nil) { zipdata, err in
                        guard err == nil else {
                            completion(err!)
                            return
                        }

                        guard let zipdata = zipdata else {
                            completion(RevocationError.nodata)
                            return
                        }
                        
                        self.processReadZipData(kid: kid, zipData: zipdata)
                        localPartition.setValue(loadedModifiedDate, forKey: "lastUpdatedDate")
                        group.leave()
                    }
                } else {
                    let loadedChunks = partition.chunks
                    for chunkObj in localChunks {
                        let chunk = chunkObj as? Chunk
                        if let _ = loadedChunks.filter({ $0.key == (chunk?.value(forKey: "cid") as! String) }).first {
                            DispatchQueue.main.async {
                                self.revocationDataManager.deleteChunk(chunk!)
                            }
                        }
                    }
                    for chunk in loadedChunks {
                        let chunkID = chunk.key
                        let loadedSlices = chunk.value
                        if let localChunk: Chunk = localChunks.filter({ ($0 as! Chunk).value(forKey: "cid") as! String == chunkID }).first as? Chunk {

                            let cid = localChunk.value(forKey: "cid") as? String
                            let localSlices = localChunk.value(forKey: "slices") as? NSOrderedSet
                            
                            for sliceObj in localSlices ?? [] {
                                if let slice = sliceObj as? Slice, let _ = loadedSlices.filter({ $0.key == (slice.value(forKey: "hashID") as! String) }).first {
                                    DispatchQueue.main.async {
                                        self.revocationDataManager.deleteSlice(slice)
                                    }
                                }
                            }

                            for loadedSlice in loadedSlices {
                                let sliceDateStr = loadedSlice.key
                                let sliceDate = Date(rfc3339DateTimeString: sliceDateStr)
                                let sliceModel = loadedSlice.value
                                if let localSlice: Slice = localSlices?.filter({ ($0 as! Slice).value(forKey: "hashID") as! String == sliceModel.hash }).first as? Slice {
                                    let hashID = localSlice.value(forKey: "hashID") as? String
                                    let sliceExpDate = localSlice.value(forKey: "expiredDate") as! Date

                                    if sliceExpDate < todayDate {
                                        DispatchQueue.main.async {
                                            self.revocationDataManager.deleteSlice(kid: kid, id: pid, cid: cid!, hashID: hashID!)
                                        }
                                    }
                                    if sliceExpDate != sliceDate {
                                        self.revocationService.getRevocationPartitionChunkSliceSingle(for: kid, id: pid, cid: chunkID, sid: sliceModel.hash) { data, err in
                                            guard err == nil else {
                                                completion(err!)
                                                return
                                            }

                                            guard let data = data else {
                                                completion(RevocationError.nodata)
                                                return
                                            }
                                            self.processReadZipData(kid: kid, zipData: data)
                                        }
                                    }
                                    
                                } else {
                                    //slice is absent
                                }
                            }
                        } else {
                            // local chunk is absent
                            if Thread.isMainThread {
                                revocationDataManager.createAndSaveChunk(kid: kid, id: pid, cid: chunkID, sliceModel: loadedSlices)
                            } else {
                                DispatchQueue.main.sync {
                                    self.revocationDataManager.createAndSaveChunk(kid: kid, id: pid, cid: chunkID, sliceModel: loadedSlices)
                                }
                            }
                            group.enter()
                            self.revocationService.getRevocationPartitionChunk(for: kid, id: pid, cid: chunkID, completion: { data, err in
                                guard err == nil else {
                                    completion(err!)
                                    return
                                }

                                guard let data = data else {
                                    completion(RevocationError.nodata)
                                    return
                                }
                                self.processReadZipData(kid: kid, zipData: data)
                                group.leave()
                            })

                        }
                    }
                }
            } else {
                // local partition is absent and should be removed
            }
        } // partitions
        
        group.notify(queue: .main) {
             completion(nil)
        }
    }
    
    // MARK: - process Zip

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
                DispatchQueue.main.async {
                    self.revocationDataManager.saveMetadataHashes(sliceHashes: [sliceMetadata])
                }
            }
        } catch {
            print("Data error")
        }
    }
}
