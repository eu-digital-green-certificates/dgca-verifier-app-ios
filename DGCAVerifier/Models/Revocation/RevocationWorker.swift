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
    init(service: RevocationServiceProtocol = RevocationService(baseServicePath: SharedConstants.revocationServiceBase)) {
        self.revocationService = service
    }
    
    let revocationCoreDataManager: RevocationCoreDataManager = RevocationCoreDataManager()
    let revocationService: RevocationServiceProtocol
    var loadedRevocations: [RevocationModel]?
    
    // MARK: - Work with Revocations
    func processReloadRevocations(completion: @escaping ProcessingCompletion) {
        
        self.revocationService.getRevocationLists {[unowned self] revocations, etag, err in
            guard err == nil else { completion(.network(reason: err!.localizedDescription)); return }
            guard let revocations = revocations, !revocations.isEmpty,
                let etag = etag else { completion(.nodata); return }
            
            SecureKeyChain.save(key: "verifierETag", data: Data(etag.utf8))
            let (loadPartList, updatePartList) = self.processReviewRevocations(revocations)
            
            let group = DispatchGroup()
            group.enter()
            self.processDownloadNewRevocations(loadPartList) { err in
                guard err == nil else { completion(err!); return }
                group.leave()
            }
            group.enter()
            self.processUpdateExistedRevocations(updatePartList) { err in
                guard err == nil else { completion(err!); return }
                group.leave()
            }
            
            group.notify(queue: .main) {
                completion(nil)
            }
        }
    }
    
    private func processReviewRevocations(_ models: [RevocationModel]) -> ([RevocationModel], [RevocationModel]) {
        // 8) Delete all KID entries in all tables which are not on this list.
        
        var newlyAddedRevocations = [RevocationModel]()
        var revocationsToReload = [RevocationModel]()
        let currentRevocations = readLocalRevocations() ?? []
        
        for revocationObject in currentRevocations {
            let revocation = revocationObject as! Revocation
            guard let localModel = makeRevocationModel(revocation: revocation) else { continue }
            let todayDate = Date()
  
            if let loadedModel = models.filter({ $0.kid == localModel.kid }).first {
                // 9) Check if “Mode” was changed. If yes, delete all associated entries with the KID.
                let loadedModifiedDate = Date(rfc3339DateTimeString: loadedModel.lastUpdated) ?? Date.distantPast
                
                if localModel.expires < todayDate {
                    removeRevocation(kid: localModel.kid)
                    
                } else if loadedModel.mode != localModel.mode {
                    removeRevocation(kid: localModel.kid)
                    saveRevocation(model: loadedModel)
                    
                    newlyAddedRevocations.append(loadedModel)
                
                } else if localModel.lastUpdated != loadedModifiedDate {
                    revocationsToReload.append(loadedModel)
                }
            } else {
                removeRevocation(kid: localModel.kid)
            }
        }
        
        for model in models {
            if currentRevocations.filter({ ($0.value(forKey: "kid") as? String) == model.kid }).isEmpty {
                saveRevocation(model: model)
                newlyAddedRevocations.append(model)
            }
        }
        return (newlyAddedRevocations, revocationsToReload)
    }
    
    private func processDownloadNewRevocations(_ revocations: [RevocationModel], completion: @escaping ProcessingCompletion) {
       self.downloadNewRevocations(revocations: revocations) { partitions, err in
            guard err == nil else {
                completion(err!)
                return
            }
            
            if let partitions = partitions, !partitions.isEmpty {
                self.downloadChunkMetadata(partitions: partitions) { err in
                    guard err == nil else {
                        completion(err!)
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }

    private func downloadNewRevocations(revocations: [RevocationModel], completion: @escaping PartitionProcessingCompletion) {
        let center = NotificationCenter.default
        let group = DispatchGroup()
        var partitionsForLoad = [PartitionModel]()
        var index: Float = 0.0
        for model in revocations {
            let kidForLoad = Helper.convertToBase64url(base64: model.kid)
            group.enter()
            self.revocationService.getRevocationPartitions(for: kidForLoad, dateString: nil) {[unowned self] partitions, _, err in
                guard err == nil else {
                    completion(nil, .network(reason: err!.localizedDescription))
                    return
                }
                
                index += 1.0
                let progress: Float = index/Float(revocations.count)
                center.post(name: Notification.Name("LoadingRevocationsNotificationName"), object: nil,
                    userInfo: ["name" : "Downloading the certificate revocations database".localized, "progress" : progress] )
                if err == nil, let partitions = partitions, !partitions.isEmpty {
                    DispatchQueue.main.async {
                        self.revocationCoreDataManager.savePartitions(kid: model.kid, models: partitions)
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

    private func processUpdateExistedRevocations(_ revocations: [RevocationModel], completion: @escaping ProcessingCompletion) {
       self.downloadExistedRevocations(revocations: revocations) { partitions, err in
            guard err == nil else {
                completion(err!)
                return
            }
            
            if let partitions = partitions, !partitions.isEmpty {
                self.updateExistedPartitions(partitions) { err in
                    guard err == nil else {
                        completion(err!)
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }

    private func downloadExistedRevocations(revocations: [RevocationModel], completion: @escaping PartitionProcessingCompletion) {
        let center = NotificationCenter.default
        let group = DispatchGroup()
        var partitionsForLoad = [PartitionModel]()
        var index: Float = 0.0
        for model in revocations {
            let localRevocation = self.revocationCoreDataManager.loadRevocation(kid: model.kid)
            let lastUpdatedStr = localRevocation?.lastUpdated?.dateOffsetString
            let kidForLoad = Helper.convertToBase64url(base64: model.kid)
            group.enter()
            
            self.revocationService.getRevocationPartitions(for: kidForLoad, dateString: lastUpdatedStr) { partitions, _, err in
                guard err == nil else {
                    completion(nil, .network(reason: err!.localizedDescription))
                    return
                }
                
                index += 1.0
                let progress: Float = index/Float(revocations.count)
                center.post(name: Notification.Name("LoadingRevocationsNotificationName"), object: nil,
                    userInfo: ["name" : "Updating the certificate revocations database".localized, "progress" : progress] )
                if err == nil, let partitions = partitions, !partitions.isEmpty {
                    partitionsForLoad.append(contentsOf: partitions)
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(partitionsForLoad, nil)
        }
    }

    // MARK: - download Chunks
    private func downloadChunkMetadata(partitions: [PartitionModel], completion: @escaping ProcessingCompletion) {
        let group = DispatchGroup()

        for part in partitions {
            group.enter()

            let kidForLoad = Helper.convertToBase64url(base64: part.kid)
            self.revocationService.getRevocationPartitionChunks(for:kidForLoad, id: part.id ?? "null",
                cids: nil, dateString: nil) { [unowned self] zipdata, err in
                guard err == nil else {
                    completion(err!)
                    return
                }
                
                if let zipdata = zipdata  {
                    self.processReadZipData(kid: part.kid, zipData: zipdata)
                }
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
        var index: Float = 0.0
        let center = NotificationCenter.default
        let group = DispatchGroup()

        for loadedPartition in partitions {
            let loadedPartitionKID = loadedPartition.kid
            let loadedPartitionID = loadedPartition.id ?? "null"
            let loadedModifiedDate = Date(rfc3339DateTimeString: loadedPartition.lastUpdated) ?? Date.distantPast
            
            let localPartitions = readLocalPartitions(kid: loadedPartitionKID) ?? []
            
            index += 1.0
            let progress: Float = index/Float(partitions.count)
            center.post(name: Notification.Name("LoadingRevocationsNotificationName".localized), object: nil,
                userInfo: ["name" : "Updating the certificate revocations metadata".localized, "progress" : progress])

            let filteredPartitions = localPartitions.filter({ $0.value(forKey: "kid") as! String == loadedPartitionKID &&
                $0.value(forKey: "id") as? String == loadedPartitionID})
            
            if let localPartition = filteredPartitions.first {
                guard let localModifiedDate = localPartition.value(forKey: "lastUpdated") as? Date,
                    let localExpiredDate = localPartition.value(forKey: "expired") as? Date,
                    let localKid = localPartition.value(forKey: "kid") as? String,
                    let localPid = localPartition.value(forKey: "id") as? String,
                    let localChunks: NSOrderedSet = localPartition.value(forKey: "chunks") as? NSOrderedSet else { continue }
                
                let headerDateStr = localModifiedDate.dateOffsetString
                
                if localExpiredDate < todayDate {
                    DispatchQueue.main.async {
                        self.revocationCoreDataManager.deletePartition(kid: localKid, id: localPid)
                    }
                    
                } else if localModifiedDate != loadedModifiedDate {
                    
                    let loadedChunks = loadedPartition.chunks
                    for chunkObj in localChunks {
                        guard let localChunk = chunkObj as? Chunk else { continue }
                        
                        let loadedCIDChunks = loadedChunks.filter({ $0.key == (localChunk.value(forKey: "cid") as! String)})
                        if loadedCIDChunks.isEmpty {
                            DispatchQueue.main.async {
                                self.revocationCoreDataManager.deleteChunk(localChunk)
                            }
                        }
                    }
                    
                    for chunk in loadedChunks {
                        let loadedChunkID = chunk.key
                        let loadedSlices = chunk.value
                        if let localChunk = localChunks.filter({ ($0 as! Chunk).value(forKey: "cid") as! String == loadedChunkID }).first as? Chunk,
                            let localSlices = localChunk.value(forKey: "slices") as? NSOrderedSet {
                            
                            for sliceObj in localSlices {
                                guard let slice = sliceObj as? Slice else { continue }
                                let loadedIDSlices = loadedSlices.filter({ ($0.value).hash == (slice.value(forKey: "hashID") as! String)})
                                if loadedIDSlices.isEmpty {
                                    DispatchQueue.main.async {
                                        self.revocationCoreDataManager.deleteSlice(slice)
                                    }
                                }
                            }
                            
                            for loadedSlice in loadedSlices {
                                let loadedSliceKey = loadedSlice.key
                                let loadedSliceModel = loadedSlice.value
                                
                                let localIDSlices = localSlices.filter({($0 as! Slice).value(forKey: "hashID") as! String == loadedSliceModel.hash }) as? [Slice]
                                if let localSlice = localIDSlices?.first,
                                    let loadedSliceDate = Date(rfc3339DateTimeString: loadedSliceKey),
                                   let simpleLocalSlice = makeSimpleSlice(slice: localSlice, dateString: headerDateStr) {
                                    
                                    let simpleLoadedSlice = SimpleSlice(kid: loadedPartitionKID,
                                        partID: loadedPartitionID,
                                        chunkID: loadedChunkID,
                                        hashID: loadedSliceModel.hash,
                                        expiredDate: loadedSliceDate,
                                        hashData: nil,
                                        type: loadedSliceModel.type,
                                        dateString: headerDateStr)

                                    group.enter()
                                    self.processAndUpdateSlice(loadedSlice: simpleLoadedSlice, localSlice: simpleLocalSlice, dateString: headerDateStr) { err in
                                        guard err == nil else {
                                            completion(err!)
                                            return
                                        }
                                        group.leave()
                                    }
                                    
                                } else {
                                    group.enter()
                                    self.createAndSaveSlice(kid: loadedPartitionKID, id: loadedPartitionID, cid: loadedChunkID,
                                            sliceKey: loadedSliceKey, sliceModel: loadedSliceModel) { err in
                                        guard err == nil else { completion(err!); return }
                                        group.leave()
                                    }
                                }
                            }
                        } else {
                            // local chunk is absent
                            group.enter()
                            self.createAndSaveChunk(kid: loadedPartitionKID, id: loadedPartitionID, cid: loadedChunkID,
                                    sliceModel: loadedSlices) { err in
                                guard err == nil else {completion(err!); return }
                                group.leave()
                            }
                        }
                    }
                }
            } else {
                print("Partition kid : \(loadedPartition.kid), id: \(String(describing: loadedPartition.id)) is up to date")
            }
        } // partitions
        
        group.notify(queue: .main) {
             completion(nil)
        }
    }
    
    private func processAndUpdateSlice(loadedSlice: SimpleSlice, localSlice: SimpleSlice, dateString: String?,  completion: @escaping ProcessingCompletion) {
        
        if localSlice.expiredDate < Date() {
            DispatchQueue.main.async {
                self.revocationCoreDataManager.deleteSlice(kid: localSlice.kid, id: localSlice.partID, cid: localSlice.chunkID, hashID: localSlice.hashID)
            }
        } else if localSlice.expiredDate != loadedSlice.expiredDate || localSlice.type != loadedSlice.type {
            let kidForLoad = Helper.convertToBase64url(base64: loadedSlice.kid)
            self.revocationService.getRevocationPartitionChunkSliceSingle(for: kidForLoad, id: loadedSlice.partID,
                cid: loadedSlice.chunkID, sid: loadedSlice.hashID, dateString: dateString) { [unowned self] data, err in
                guard err == nil else {
                    completion(err!)
                    return
                }
                if let data = data  {
                    self.processReadZipData(kid: loadedSlice.kid, zipData: data)
                    print("###   Updated Slice with KID: \(loadedSlice.kid), id: \(loadedSlice.partID), cid: \(localSlice.chunkID), sid: \(localSlice.hashID)")

                }
                completion(nil)
            }
        } else {
            print("---   Slice with KID: \(loadedSlice.kid), id: \(loadedSlice.partID), cid: \(localSlice.chunkID), sid: \(localSlice.hashID) is up to date")
            completion(nil)
        }
    }
    
    private func createAndSaveSlice(kid: String, id: String, cid: String, sliceKey: String, sliceModel: SliceModel, completion: @escaping ProcessingCompletion) {
        // local chunk is absent
        if Thread.isMainThread {
            revocationCoreDataManager.createAndSaveSlice(kid: kid, id: id, cid: cid, sliceKey: sliceKey, sliceModel: sliceModel)
        } else {
            DispatchQueue.main.sync {
                self.revocationCoreDataManager.createAndSaveSlice(kid: kid, id: id, cid: cid, sliceKey: sliceKey, sliceModel: sliceModel)
            }
        }
        
        let kidForLoad = Helper.convertToBase64url(base64: kid)
        self.revocationService.getRevocationPartitionChunkSliceSingle(for: kidForLoad, id: id, cid: cid, sid: sliceModel.hash, dateString: nil) { [unowned self] data, err in
            guard err == nil else {
                completion(err!)
                return
            }
            if let data = data {
                self.processReadZipData(kid: kid, zipData: data)
            }
            completion(nil)
        }
    }

    private func createAndSaveChunk(kid: String, id: String, cid: String, sliceModel: [String : SliceModel], completion: @escaping ProcessingCompletion) {
        // local chunk is absent
        if Thread.isMainThread {
            revocationCoreDataManager.createAndSaveChunk(kid: kid, id: id, cid: cid, sliceModel: sliceModel)
        } else {
            DispatchQueue.main.sync {
                self.revocationCoreDataManager.createAndSaveChunk(kid: kid, id: id, cid: cid, sliceModel: sliceModel)
            }
        }
        
        let kidForLoad = Helper.convertToBase64url(base64: kid)
        self.revocationService.getRevocationPartitionChunk(for: kidForLoad, id: id, cid: cid, dateString: nil, completion: { [unowned self] data, err in
            guard err == nil else {
                completion(err!)
                return
            }
            if let data = data {
                self.processReadZipData(kid: kid, zipData: data)
            }
            completion(nil)
        })
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
                    self.revocationCoreDataManager.saveMetadataHashes(sliceHashes: [sliceMetadata])
                }
            }
        } catch {
            print("Data error")
        }
    }
    
    // MARK: - Auxilary methods

    private func removeRevocation(kid: String) {
        DispatchQueue.main.async {
            self.revocationCoreDataManager.removeRevocation(kid: kid)
        }
    }
 
    private func saveRevocation(model: RevocationModel) {
        DispatchQueue.main.async {
            self.revocationCoreDataManager.createAndSaveRevocations([model])
        }
    }

    private func readLocalRevocations() -> [NSManagedObject]? {
        var currentRevocations: [NSManagedObject]? //Revocation
        if Thread.isMainThread {
            currentRevocations = self.revocationCoreDataManager.currentRevocations()
        } else {
            DispatchQueue.main.sync {
                currentRevocations = self.revocationCoreDataManager.currentRevocations()
            }
        }
        return currentRevocations
    }

    private func readLocalPartitions(kid: String) -> [Partition]? {
        var localPartitions: [Partition]?
        if Thread.isMainThread {
            localPartitions = revocationCoreDataManager.loadAllPartitions(for: kid)
        } else {
            DispatchQueue.main.sync {
                localPartitions = self.revocationCoreDataManager.loadAllPartitions(for: kid)
            }
        }
        return localPartitions
    }

    private func makeRevocationModel(revocation: Revocation) -> SimpleRevocation? {
        if let localKid = revocation.value(forKey: "kid") as? String,
            let localMode = revocation.value(forKey: "mode") as? String,
            let localHashTypes = revocation.value(forKey: "hashTypes") as? String,
            let localModifiedDate = revocation.value(forKey: "lastUpdated") as? Date,
            let localExpiredDate = revocation.value(forKey: "expires") as? Date {
            
            let model = SimpleRevocation(kid: localKid, mode: localMode, hashTypes: localHashTypes, expires: localExpiredDate, lastUpdated: localModifiedDate)
            return model
        }
        return nil
    }
    
    private func makeSimpleSlice(slice: Slice, dateString: String) -> SimpleSlice? {
        if let sliceKID = slice.value(forKeyPath: "chunk.partition.kid") as? String,
           let slicePID = slice.value(forKeyPath: "chunk.partition.id") as? String,
           let sliceChunkID = slice.value(forKeyPath: "chunk.cid") as? String,
           let sliceHashID = slice.value(forKey: "hashID") as? String,
           let sliceHashData = slice.value(forKey: "hashData") as? Data,
           let sliceType = slice.value(forKey: "type") as? String,
           let sliceExpiredDate = slice.value(forKey: "expiredDate") as? Date {
            
            let model = SimpleSlice(kid: sliceKID, partID: slicePID, chunkID: sliceChunkID, hashID: sliceHashID,
                expiredDate: sliceExpiredDate, hashData: sliceHashData, type: sliceType, dateString: dateString)
            return model
        }
        return nil
    }
}
