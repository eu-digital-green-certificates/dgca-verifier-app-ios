//
//  RevocationCoreDataManager.swift
//  DCCRevocation
//
//  Created by Igor Khomiak on 04.01.2022.
//

import UIKit
import CoreData
import SwiftDGC
import SwiftUI

public enum DataBaseError: Error {
    case nodata
    case loading
    case dataBaseError(error: NSError)
}

typealias LoadingCompletion = ([NSManagedObject]?, DataBaseError?) -> Void

class RevocationCoreDataManager: NSObject {
    
    var managedContext: NSManagedObjectContext! = {
        return RevocationCoreDataStorage.shared.persistentContainer.viewContext
    }()
    
    // MARK: - Revocations
    func clearAllData() {
        let fetchRequest = NSFetchRequest<Revocation>(entityName: "Revocation")
        
        do {
            let revocations = try managedContext.fetch(fetchRequest)
            DGCLogger.logInfo("Start clearing. Extracted \(revocations.count) Revocations for deleting")
            for revocationObject in revocations {
                managedContext.delete(revocationObject)
            }
            if !revocations.isEmpty {
                RevocationCoreDataStorage.shared.saveContext()
                DGCLogger.logInfo("== Finished clearing.")
            }

        } catch let error as NSError {
            DGCLogger.logInfo("Could not fetch Revocations for deleting with Error: \(error.localizedDescription)")
        } catch {
            DGCLogger.logInfo("Error: Could not fetch Revocations for deleting.")
        }
    }
    
    func loadRevocation(kid: String) -> Revocation? {
        let fetchRequest = NSFetchRequest<Revocation>(entityName: "Revocation")
        let predicate: NSPredicate = NSPredicate(format: "kid == %@", argumentArray: [kid])
        fetchRequest.predicate = predicate
        
        do {
            let revocations = try managedContext.fetch(fetchRequest)
            DGCLogger.logInfo("== Extracted \(revocations.count) revocations for kid: \(kid)")

            return revocations.first
            
        } catch let error as NSError {
            DGCLogger.logInfo("Could not fetch revocation for kid: \(kid) with Error: \(error), \(error.userInfo) ")
        } catch {
            DGCLogger.logInfo("Error: Could not fetch for kid: \(kid)")
        }
        return nil
    }

    func removeRevocation(kid: String) {
        let fetchRequest = NSFetchRequest<Revocation>(entityName: "Revocation")
        let predicate:  NSPredicate = NSPredicate(format: "kid == %@", argumentArray: [kid])
        fetchRequest.predicate = predicate
        
        do {
            let revocations = try managedContext.fetch(fetchRequest)
            DGCLogger.logInfo("++ Extracted \(revocations.count) Revocations for deleting")
            for revocationObject in revocations {
                managedContext.delete(revocationObject)
            }
            if !revocations.isEmpty {
                RevocationCoreDataStorage.shared.saveContext()
                DGCLogger.logInfo("== Deleted all Revocations with KID \(kid)")
            }
            
        } catch let error as NSError {
            DGCLogger.logInfo("Could not fetch Revocations for deleting with error: \(error.localizedDescription)")
        } catch {
            DGCLogger.logInfo("Error: Could not fetch Revocations for deleting.")
        }
    }
    
    func currentRevocations() -> [Revocation] {
        let fetchRequest = NSFetchRequest<Revocation>(entityName: "Revocation")
        do {
            let revocations = try managedContext.fetch(fetchRequest)
            DGCLogger.logInfo("== Extracted \(revocations.count) Revocations")
            return revocations
            
        } catch let error as NSError {
            DGCLogger.logInfo("Could not fetch Revocations with error: \(error.localizedDescription)")
        } catch {
            DGCLogger.logInfo("Error: Could not fetch Revocations.")
        }
        return []
    }
    
    func createAndSaveRevocations(_ models: [RevocationModel]) {
        for model in models {
            let kid = model.kid
             
            let entity = NSEntityDescription.entity(forEntityName: "Revocation", in: managedContext)!
            let revocation = Revocation(entity: entity, insertInto: managedContext)
            
            revocation.setValue(kid, forKey: "kid")
            let hashTypes = model.hashTypes.joined(separator: ",")
            revocation.setValue(hashTypes, forKey: "hashTypes")
            revocation.setValue(model.mode, forKey: "mode")
            
            if let expDate = Date(rfc3339DateTimeString: model.expires) {
                revocation.setValue(expDate, forKey: "expires")
            }
            if let lastUpdated = Date(rfc3339DateTimeString: model.lastUpdated) {
                revocation.setValue(lastUpdated, forKey: "lastUpdated")
            }
        }
        
        if !models.isEmpty {
            RevocationCoreDataStorage.shared.saveContext()
            DGCLogger.logInfo("-- Created Revocations for KID: \(models.first!.kid)")
        }
    }

    func saveMetadataHashes(sliceHashes: [SliceMetaData]) {
        var isChanged = false
        for dataSliceModel in sliceHashes {
            let kid = dataSliceModel.kid
            if let sliceObject = loadSlice(kid: kid, id: dataSliceModel.id,
                cid: dataSliceModel.cid, hashID: dataSliceModel.hashID) {
             
                let generatedData = dataSliceModel.contentData
                sliceObject.setValue(generatedData, forKey: "hashData")
                isChanged = true
            }
        }
        if isChanged {
            RevocationCoreDataStorage.shared.saveContext()
        }
    }

    func deleteExpiredRevocations() {
        let date = Date()
        let fetchRequest = NSFetchRequest<Revocation>(entityName: "Revocation")
        let predicate:  NSPredicate = NSPredicate(format: "expires < %@", argumentArray: [date])
        fetchRequest.predicate = predicate
        do {
            let revocations = try managedContext.fetch(fetchRequest)
            revocations.forEach { managedContext.delete($0) }
            if !revocations.isEmpty {
                RevocationCoreDataStorage.shared.saveContext()
                DGCLogger.logInfo("-- Deleted \(revocations.count) revocations for expiredDate for today")
            }
            
        } catch let error as NSError {
            DGCLogger.logInfo("Could not fetch revocations. Error: \(error.localizedDescription) for expired today")
        } catch {
            DGCLogger.logInfo("Error: Could not fetch revocations for expiredDate today.")
        }
    }

    // MARK: - Partitions
    func savePartitions(kid: String, models: [PartitionModel]) {
        let revocation = loadRevocation(kid: kid)
        for model in models {
            let entity = NSEntityDescription.entity(forEntityName: "Partition", in: managedContext)!
            let partition = Partition(entity: entity, insertInto: managedContext)
            partition.setValue(kid, forKey: "kid")
            if let pid = model.id {
                partition.setValue(pid, forKey: "id")
            } else {
                partition.setValue("null", forKey: "id")
            }
            
            if let expDate = Date(rfc3339DateTimeString: model.expired) {
                partition.setValue(expDate, forKey: "expired")
            }
            
            if let updatedDate = Date(rfc3339DateTimeString: model.lastUpdated) {
                partition.setValue(updatedDate, forKey: "lastUpdated")
            }
            
            if let xValue = model.x {
                partition.setValue(xValue, forKey: "x")
            } else {
                partition.setValue("null", forKey: "x")
            }
            
            if let yValue = model.y {
                partition.setValue(yValue, forKey: "y")
            } else {
                partition.setValue("null", forKey: "y")
            }
            
            let chunkParts = createChunks(chunkModels: model.chunks, partition: partition)
            partition.setValue(chunkParts, forKey: "chunks")
            partition.setValue(revocation, forKey: "revocation")
        }
        if !models.isEmpty {
            RevocationCoreDataStorage.shared.saveContext()
            DGCLogger.logInfo("== Saved Partitions for KID: \(kid)")
        }
    }
    
    func createAndSaveChunk(kid: String, id: String, cid: String, sliceModel: [String : SliceModel]) {
        let partition = loadPartition(kid: kid, id: id)
        let chunkEntity = NSEntityDescription.entity(forEntityName: "Chunk", in: managedContext)!
        let chunk = Chunk(entity: chunkEntity, insertInto: managedContext)
        
        let slices: NSMutableOrderedSet = []
        for sliceKey in sliceModel.keys {
            let slice: Slice = createSlice(expDate: sliceKey, sliceModel: sliceModel[sliceKey]!)
            slice.setValue(chunk, forKey: "chunk")
            slices.add(slice)
        }
        chunk.setValue(cid, forKey: "cid")
        chunk.setValue(slices, forKey: "slices")
        chunk.setValue(partition, forKey: "partition")
        
        RevocationCoreDataStorage.shared.saveContext()
    }
    
    func createAndSaveSlice(kid: String, id: String, cid: String, sliceKey: String, sliceModel: SliceModel) {
        if let chunk = loadChunk(kid: kid, id: id, cid: cid) {
            let slice: Slice = createSlice(expDate: sliceKey, sliceModel: sliceModel)
            slice.setValue(chunk, forKey: "chunk")
            let slices = chunk.value(forKey: "slices") as? NSMutableOrderedSet
            slices?.add(slice)
            chunk.setValue(slices, forKey: "slices")
            
            RevocationCoreDataStorage.shared.saveContext()
        }
    }
    
    func deleteExpiredPartitions() {
        let date = Date()
        let fetchRequest = NSFetchRequest<Partition>(entityName: "Partition")
        let predicate:  NSPredicate = NSPredicate(format: "expires < %@", argumentArray: [date])
        fetchRequest.predicate = predicate
        do {
            let partitions = try managedContext.fetch(fetchRequest)
            partitions.forEach { managedContext.delete($0) }
            if !partitions.isEmpty {
                RevocationCoreDataStorage.shared.saveContext()
                DGCLogger.logInfo("==  Deleted \(partitions.count) partitions for today")
            }
        
        } catch let error as NSError {
            DGCLogger.logInfo("Could not fetch revocations. Error: \(error.localizedDescription) for expiredDate: \(date)")
        } catch {
            DGCLogger.logInfo("Error: Could not fetch revocations for expiredDate: \(date).")
        }
    }
    
    func deletePartition(kid: String, id: String) {
        let fetchRequest = NSFetchRequest<Partition>(entityName: "Partition")
        let predicate: NSPredicate = NSPredicate(format: "kid == %@ AND id == %@", argumentArray: [kid, id])
        fetchRequest.predicate = predicate
        do {
            let partitions = try managedContext.fetch(fetchRequest)
            partitions.forEach { managedContext.delete($0) }
            
            if !partitions.isEmpty {
                RevocationCoreDataStorage.shared.saveContext()
                DGCLogger.logInfo("==  Deleted \(partitions.count) partitions for kid: \(kid), id: \(id)")
            }

        } catch let error as NSError {
            DGCLogger.logInfo("Could not fetch revocations. Error: \(error.localizedDescription) with kid: \(kid), id: \(id)")
        } catch {
            DGCLogger.logInfo("Error: Could not fetch revocations with kid: \(kid), id: \(id)")
        }
    }
  
    func deleteChunk(_ chunk: Chunk) {
        managedContext.delete(chunk)
        RevocationCoreDataStorage.shared.saveContext()
    }

    func deleteSlice(_ slice: Slice) {
        managedContext.delete(slice)
        RevocationCoreDataStorage.shared.saveContext()
    }

    func deleteSlice(kid: String, id: String, cid: String, hashID: String) {
        let fetchRequest = NSFetchRequest<Slice>(entityName: "Slice")
        let predicate = NSPredicate(format: "chunk.partition.kid == %@ AND chunk.partition.id == %@ AND chunk.cid == %@ AND hashID == %@",
            argumentArray: [kid, id, cid, hashID])
        fetchRequest.predicate = predicate
        
        do {
            let slices = try managedContext.fetch(fetchRequest)
            slices.forEach { managedContext.delete($0) }
            
            if !slices.isEmpty {
                RevocationCoreDataStorage.shared.saveContext()
                DGCLogger.logInfo("==  Deleted \(slices.count) slices for kid: \(kid), id: \(id), cid: \(cid), hashID: \(hashID)")
            }
            
        } catch let error as NSError {
            DGCLogger.logInfo("Could not fetch slices. Error: \(error.localizedDescription) for for kid: \(kid), id: \(id), cid: \(cid), hashID: \(hashID)")
        } catch {
            DGCLogger.logInfo("Could not fetch slices for for kid: \(kid), id: \(id), cid: \(cid), hashID: \(hashID)")
        }
    }

    func loadAllPartitions(for kid: String) -> [Partition]? {
        let fetchRequest = NSFetchRequest<Partition>(entityName: "Partition")
        let predicate: NSPredicate = NSPredicate(format: "kid == %@", argumentArray: [kid])
        fetchRequest.predicate = predicate
        
        do {
            let partitions = try managedContext.fetch(fetchRequest)
            DGCLogger.logInfo("==  Extracted \(partitions.count) partitions for kid: \(kid)")
            return partitions
        } catch let error as NSError {
            DGCLogger.logInfo("Could not fetch Partitions with Error:\(error), \(error.userInfo) with kid: \(kid)")
        } catch {
            DGCLogger.logInfo("Error: Could not fetch Partitions with kid: \(kid)")
        }
        return nil
    }
    
    func loadPartition(kid: String, id: String) -> Partition? {
        let fetchRequest = NSFetchRequest<Partition>(entityName: "Partition")
        let predicate: NSPredicate = NSPredicate(format: "kid == %@ AND id == %@", argumentArray: [kid, id])
        fetchRequest.predicate = predicate
        
        do {
            let partitions = try managedContext.fetch(fetchRequest)
            DGCLogger.logInfo("==  Extracted \(partitions.count) partitions for kid: \(kid), id: \(id)")
            return partitions.first
            
        } catch let error as NSError {
            DGCLogger.logInfo("Could not fetch Partitions: \(error), \(error.userInfo) for kid: \(kid), id: \(id)")
        } catch {
            DGCLogger.logInfo("Error: Could not fetch Partitions for kid: \(kid), id: \(id)")
        }
        return nil
    }

    func loadChunk(kid: String, id: String, cid: String) -> Chunk? {
        let today = Date()
        let fetchRequest = NSFetchRequest<Chunk>(entityName: "Chunk")
        let predicate: NSPredicate = NSPredicate(format: "partition.kid == %@ AND partition.expired > %@ AND partition.id == %@ AND cid == %@", argumentArray: [kid, today, id, cid])
        
        fetchRequest.predicate = predicate
        do {
            let chunks = try managedContext.fetch(fetchRequest)
            DGCLogger.logInfo("==  Extracted \(chunks.count) chunk(s) for kid: \(kid), id: \(id), cid: \(cid)")
            return chunks.first
        } catch let error as NSError {
            DGCLogger.logInfo("Could not fetch chunks with Error: \(error), \(error.userInfo) for kid: \(kid), id: \(id), cid: \(cid)")
        } catch {
            DGCLogger.logInfo("Error: Could not fetch chunks for kid: \(kid), id: \(id), cid: \(cid)")
        }
        return nil
    }

    func loadSlice(kid: String, id: String, cid: String, hashID: String) -> Slice? {
        let fetchRequest = NSFetchRequest<Slice>(entityName: "Slice")
        let today = Date()

        let predicate: NSPredicate = NSPredicate(format: "chunk.partition.kid == %@ AND chunk.partition.expired > %@ AND chunk.partition.id == %@ AND chunk.cid == %@ AND hashID == %@ AND expiredDate > %@", argumentArray: [kid, today, id, cid, hashID, today])
        
        fetchRequest.predicate = predicate
        do {
            let slices = try managedContext.fetch(fetchRequest)
            DGCLogger.logInfo("==  Extracted \(slices.count) slice(s) for kid: \(kid), id: \(id), cid: \(cid), hashID: \(hashID)")
            return slices.first
            
        } catch let error as NSError {
            DGCLogger.logInfo("Could not fetch slices with Error: \(error), \(error.userInfo) for kid: \(kid), id: \(id), cid: \(cid), hashID: \(hashID)")
            
        } catch {
            DGCLogger.logInfo("Error: Could not fetch slices for kid: \(kid), id: \(id), cid: \(cid), hashID: \(hashID)")
        }
        return nil
    }
    
    // MARK: - Chunks & Slices
    func loadSlices(kid: String, x: String, y: String, section cid: String) -> [Slice]? {
        let fetchRequest = NSFetchRequest<Slice>(entityName: "Slice")
        let today = Date()
        let predicate = NSPredicate(format: "chunk.partition.kid == %@ AND chunk.partition.expired > %@ AND chunk.partition.x == %@ AND chunk.partition.y == %@ AND chunk.cid == %@ AND expiredDate > %@", argumentArray: [kid, today, x, y, cid, today])
        fetchRequest.predicate = predicate
        
        do {
            let slices = try managedContext.fetch(fetchRequest)
            DGCLogger.logInfo("==  Extracted \(slices.count) slices for kid: \(kid), x: \(x), y: \(y)")
            return slices
            
        } catch let error as NSError {
            DGCLogger.logInfo("Could not fetch slices with Error: \(error), \(error.userInfo)")
        
        } catch {
            DGCLogger.logInfo("Error: Could not fetch slices.")
        }
        return nil
    }
    
    private func createSlice(expDate: String, sliceModel: SliceModel) -> Slice {
        let sliceEntity = NSEntityDescription.entity(forEntityName: "Slice", in: managedContext)!
        let slice = Slice(entity: sliceEntity, insertInto: managedContext)
        if let expDate = Date(rfc3339DateTimeString: expDate) {
            slice.setValue(expDate, forKey: "expiredDate")
        }
        slice.setValue(sliceModel.version, forKey: "version")
        slice.setValue(sliceModel.type, forKey: "type")
        slice.setValue(sliceModel.hash, forKey: "hashID")
        slice.setValue(nil, forKey: "hashData")
        return slice
    }

    private func createChunks(chunkModels: [String : SliceDict], partition: Partition) -> NSOrderedSet {
        let chunkSet: NSMutableOrderedSet = []
        for key in chunkModels.keys  {
            let chunkEntity = NSEntityDescription.entity(forEntityName: "Chunk", in: managedContext)!
            let chunk = Chunk(entity: chunkEntity, insertInto: managedContext)
            guard let sliceDict = chunkModels[key] else { return chunkSet }
            let slices: NSMutableOrderedSet = []
            for sliceKey in sliceDict.keys {
                let slice: Slice = createSlice(expDate: sliceKey, sliceModel: sliceDict[sliceKey]!)
                slice.setValue(chunk, forKey: "chunk")
                slices.add(slice)
            }
            chunk.setValue(key, forKey: "cid")
            chunk.setValue(slices, forKey: "slices")
            chunk.setValue(partition, forKey: "partition")
            chunkSet.add(chunk)
        }
        return chunkSet
    }
}
