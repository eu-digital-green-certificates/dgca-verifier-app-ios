//
//  RevocationManager.swift
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

class RevocationManager: NSObject {
        
    var managedContext: NSManagedObjectContext! = {
        return RevocationDataStorage.shared.persistentContainer.viewContext
    }()

    
    // MARK: - Revocations
    func clearAllData() {
        let fetchRequest = NSFetchRequest<Revocation>(entityName: "Revocation")
        
        do {
            let revocations = try managedContext.fetch(fetchRequest)
            print("Extracted \(revocations.count) Revocations for deleting")
            for revocationObject in revocations {
                let kidStr = revocationObject.value(forKey: "kid")
                managedContext.delete(revocationObject)
                print("Deleted Revocation \(kidStr ?? "")")
            }
            RevocationDataStorage.shared.saveContext()
            
        } catch let error as NSError {
            print("Could not fetch Revocations for deleting: \(error.localizedDescription)")
            return
        } catch {
            print("Could not fetch Revocations for deleting.")
            return
        }
    }
    
    func loadRevocation(kid: String) -> Revocation? {
        let kidConverted = Helper.convertToBase64url(base64: kid)

        let fetchRequest = NSFetchRequest<Revocation>(entityName: "Revocation")
        let predicate: NSPredicate = NSPredicate(format: "kid == %@", argumentArray: [kidConverted])
        fetchRequest.predicate = predicate
        
        do {
            var revocations = try managedContext.fetch(fetchRequest)
            print("  Extracted \(revocations.count) revocations for id: \(kid)")
            if revocations.count > 1 {
                while revocations.count > 1 {
                    revocations.removeLast()
                }
            }
            return revocations.first
            
        } catch let error as NSError {
            print("Could not fetch: \(error), \(error.userInfo) for id: \(kid)")
            return nil
        } catch {
            print("Could not fetch for id: \(kid).")
            return nil
        }
    }

    func removeRevocation(kid: String) {
        let fetchRequest = NSFetchRequest<Revocation>(entityName: "Revocation")
        let predicate:  NSPredicate = NSPredicate(format: "kid == %@", argumentArray: [kid])
        fetchRequest.predicate = predicate
        
        do {
            let revocations = try managedContext.fetch(fetchRequest)
            print("Extracted \(revocations.count) Revocations for deleting")
            for revocationObject in revocations {
                managedContext.delete(revocationObject)
                print("Deleted Revocation \(kid)")
            }
            RevocationDataStorage.shared.saveContext()
            
        } catch let error as NSError {
            print("Could not fetch Revocations for deleting: \(error.localizedDescription)")
            return
        } catch {
            print("Could not fetch Revocations for deleting.")
            return
        }
    }
    
    func currentRevocations() -> [Revocation] {
        let fetchRequest = NSFetchRequest<Revocation>(entityName: "Revocation")
        do {
            let revocations = try managedContext.fetch(fetchRequest)
            print("== Extracted \(revocations.count) Revocations")
            return revocations
            
        } catch let error as NSError {
            print("Could not fetch Revocations: \(error.localizedDescription)")
            return []
        } catch {
            print("Could not fetch Revocations.")
            return []
        }
    }
    
    func saveRevocations(_ models: [RevocationModel]) {
        
        for model in models {
            let kidConverted = Helper.convertToBase64url(base64: model.kid)
             
            let entity = NSEntityDescription.entity(forEntityName: "Revocation", in: managedContext)!
            let revocation = Revocation(entity: entity, insertInto: managedContext)
            
            revocation.setValue(kidConverted, forKey: "kid")
            let hashTypes = model.hashTypes.joined(separator: ",")
            revocation.setValue(hashTypes, forKey: "hashTypes")
            revocation.setValue(model.mode, forKey: "mode")
            
            if let expDate = Date(rfc3339DateTimeString: model.expires) {
                revocation.setValue(expDate, forKey: "expires")
            }
            if let lastUpdated = Date(rfc3339DateTimeString: model.lastUpdated) {
                revocation.setValue(lastUpdated, forKey: "lastUpdated")
            }
            print("-- Added Revocation with KID: \(kidConverted)")
        }
        
        RevocationDataStorage.shared.saveContext()
    }

    func saveMetadataHashes(sliceHashes: [SliceMetaData]) {
        for dataSliceModel in sliceHashes {
            let kidConverted = Helper.convertToBase64url(base64: dataSliceModel.kid)
            guard let sliceObject = loadSlice(kid: kidConverted, id: dataSliceModel.id,
                cid: dataSliceModel.cid, hashID: dataSliceModel.hashID) else { continue }
             
            let generatedData = dataSliceModel.contentData
            sliceObject.setValue(generatedData, forKey: "hashData")
        }

        RevocationDataStorage.shared.saveContext()
    }

    func deleteExpiredRevocations(for date: Date) {
        let fetchRequest = NSFetchRequest<Revocation>(entityName: "Revocation")
        let predicate:  NSPredicate = NSPredicate(format: "expires < %@", argumentArray: [date])
        fetchRequest.predicate = predicate
        do {
            let revocations = try managedContext.fetch(fetchRequest)
            revocations.forEach { managedContext.delete($0) }
            print("-- Deleted \(revocations.count) revocations for expiredDate: \(date)")
            
            RevocationDataStorage.shared.saveContext()
 
        } catch let error as NSError {
            print("Could not fetch revocations. Error: \(error.localizedDescription) for expiredDate: \(date)")
            return
        } catch {
            print("Could not fetch revocations for expiredDate: \(date).")
            return
        }
    }

    // MARK: - Partitions

    func savePartitions(kid: String, models: [PartitionModel]) {
        let kidConverted = Helper.convertToBase64url(base64: kid)
        
        print("Start saving Partitions for KID: \(kidConverted)")
        let revocation = loadRevocation(kid: kidConverted)
        for model in models {
            let entity = NSEntityDescription.entity(forEntityName: "Partition", in: managedContext)!
            let partition = Partition(entity: entity, insertInto: managedContext)
            partition.setValue(kidConverted, forKey: "kid")
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
        
        RevocationDataStorage.shared.saveContext()
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
    }
    
    func deleteExpiredPartitions(for date: Date) {
        let fetchRequest = NSFetchRequest<Partition>(entityName: "Partition")
        let predicate:  NSPredicate = NSPredicate(format: "expires < %@", argumentArray: [date])
        fetchRequest.predicate = predicate
        do {
            let partitions = try managedContext.fetch(fetchRequest)
            partitions.forEach { managedContext.delete($0) }
            print("  Deleted \(partitions.count) partitions for expiredDate: \(date)")
            RevocationDataStorage.shared.saveContext()
            
        } catch let error as NSError {
            print("Could not fetch revocations. Error: \(error.localizedDescription) for expiredDate: \(date)")
            return
        } catch {
            print("Could not fetch revocations for expiredDate: \(date).")
            return
        }
    }
    
    func deletePartition(kid: String, id: String) {
        let fetchRequest = NSFetchRequest<Partition>(entityName: "Partition")
        let predicate: NSPredicate = NSPredicate(format: "kid == %@ AND id == %@", argumentArray: [kid, id])
        fetchRequest.predicate = predicate
        do {
            let partitions = try managedContext.fetch(fetchRequest)
            partitions.forEach { managedContext.delete($0) }
            print("  Deleted \(partitions.count) partitions for id: \(id)")
            
            RevocationDataStorage.shared.saveContext()
            
        } catch let error as NSError {
            print("Could not fetch revocations. Error: \(error.localizedDescription) for expiredDate: \(id)")
            return
        } catch {
            print("Could not fetch revocations for expiredDate: \(id)")
            return
        }
    }
  
    func deleteChunk(_ chunk: Chunk) {
        managedContext.delete(chunk)
        RevocationDataStorage.shared.saveContext()
    }

    func deleteSlice(_ slice: Slice) {
        managedContext.delete(slice)
        RevocationDataStorage.shared.saveContext()
    }

    func deleteSlice(kid: String, id: String, cid: String, hashID: String) {
        let fetchRequest = NSFetchRequest<Slice>(entityName: "Slice")
        let predicate = NSPredicate(format: "chunk.partition.kid == %@ AND chunk.partition.id == %@ AND chunk.id == %@ AND hashID == %@", argumentArray: [kid, id, cid, hashID])
        fetchRequest.predicate = predicate
        do {
            let slices = try managedContext.fetch(fetchRequest)
            slices.forEach { managedContext.delete($0) }
            print("-- Deleted \(slices.count) slices for id: \(hashID)")
            
            RevocationDataStorage.shared.saveContext()
            
        } catch let error as NSError {
            print("Could not fetch slices. Error: \(error.localizedDescription) for expiredDate: \(id)")
            return
        } catch {
            print("Could not fetch slices for expiredDate: \(id)")
            return
        }
    }

    
    func loadAllPartitions(for kid: String) -> [Partition]? {
        let fetchRequest = NSFetchRequest<Partition>(entityName: "Partition")
        let predicate:  NSPredicate = NSPredicate(format: "kid == %@", argumentArray: [kid])
        fetchRequest.predicate = predicate
        
        do {
            let partitions = try managedContext.fetch(fetchRequest)
            print("  Extracted \(partitions.count) partitions for id: \(kid)")
            return partitions
        } catch let error as NSError {
            print("Could not fetch Partitions: \(error), \(error.userInfo) for id: \(kid)")
            return nil
        } catch {
            print("Could not fetch Partitions for id: \(kid)")
            return nil
        }
    }

    
    func loadPartition(kid: String, id: String) -> Partition? {
        let fetchRequest = NSFetchRequest<Partition>(entityName: "Partition")
        let predicate:  NSPredicate = NSPredicate(format: "kid == %@ AND id == %@", argumentArray: [kid, id])
        fetchRequest.predicate = predicate
        
        do {
            let partitions = try managedContext.fetch(fetchRequest)
            print("  Extracted \(partitions.count) partitions for kid: \(kid), id: \(id)")
            return partitions.first
            
        } catch let error as NSError {
            print("Could not fetch Partitions: \(error), \(error.userInfo) for kid: \(kid), id: \(id)")
            return nil
        } catch {
            print("Could not fetch Partitions for kid: \(kid), id: \(id)")
            return nil
        }
    }

    func loadSlice(kid: String, id: String, cid: String, hashID: String) -> Slice? {
        let fetchRequest = NSFetchRequest<Slice>(entityName: "Slice")
        let predicate:  NSPredicate = NSPredicate(format: "chunk.partition.kid == %@ AND chunk.partition.id == %@ AND chunk.cid == %@ AND hashID == %@", argumentArray: [kid, id, cid, hashID])
        fetchRequest.predicate = predicate
        
        do {
            let slices = try managedContext.fetch(fetchRequest)
            print("== Extracted \(slices.count) slice(s) for kid: \(kid), pid: \(id), cid: \(cid), sid: \(hashID)")
            return slices.first
        } catch let error as NSError {
            print("Could not fetch slices: \(error), \(error.userInfo) for kid: \(kid), id: \(id)")
            return nil
        } catch {
            print("Could not fetch slices for kid: \(kid), id: \(id)")
            return nil
        }
    }
    
    // MARK: - Chunks & Slices
    func loadSlices(kid: String, x: String, y: String, section cid: String) -> [Slice]? {
        let kidConverted = Helper.convertToBase64url(base64: kid)
        let fetchRequest = NSFetchRequest<Slice>(entityName: "Slice")
        let predicate = NSPredicate(format: "chunk.partition.kid == %@ AND chunk.partition.x == %@ AND chunk.partition.y == %@ AND chunk.cid == %@", argumentArray: [kidConverted, x, y, cid])
                
        fetchRequest.predicate = predicate
        
        do {
            let slices = try managedContext.fetch(fetchRequest)
            print("== Extracted \(slices.count) slices for kid: \(kid), x: \(x), y: \(y)")
            
            return slices
            
        } catch let error as NSError {
          print("Could not fetch slices: \(error), \(error.userInfo)")
            //completion(nil, DataBaseError.dataBaseError(error: error))
        
        } catch {
            print("Could not fetch slices.")
            // completion(nil, DataBaseError.loading)
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
