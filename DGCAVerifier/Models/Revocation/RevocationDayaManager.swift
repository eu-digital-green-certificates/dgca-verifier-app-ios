//
//  RevocationManager.swift
//  DCCRevocation
//
//  Created by Igor Khomiak on 04.01.2022.
//

import UIKit
import CoreData
import SwiftDGC

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

    func clearAllData() {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Revocation")
        
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
    
    func removeRevocations(kid: String) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Revocation")
        let predicate:  NSPredicate = NSPredicate(format: "kid == %@", argumentArray: [kid])
        fetchRequest.predicate = predicate

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


    func currentRevocationKIDs() -> [String]? {
        var revocStrings = [String]()
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Revocation")
        do {
            let revocations = try managedContext.fetch(fetchRequest)
            print("Extracted \(revocations.count) Revocations for deleting")
            for revocationObject in revocations {
                if let kidStr = revocationObject.value(forKey: "kid") as? String {
                    revocStrings.append(kidStr)
                }
            }
            return revocStrings
            
        } catch let error as NSError {
            print("Could not fetch Revocations: \(error.localizedDescription)")
            return nil
        } catch {
            print("Could not fetch Revocations.")
            return nil
        }
    }
    
    func saveRevocations(models: [RevocationModel]) {
        print("Start saving Revocations")
        
        for model in models {
            let kidConverted = Helper.convertToBase64url(base64: model.kid)
             
            let entity = NSEntityDescription.entity(forEntityName: "Revocation", in: managedContext)!
            let revocation = NSManagedObject(entity: entity, insertInto: managedContext)
            
            revocation.setValue(kidConverted, forKeyPath: "kid")
            let hashTypes = model.hashType.joined(separator: ",")
            revocation.setValue(hashTypes, forKeyPath: "hashType")
            revocation.setValue(model.mode, forKeyPath: "mode")
            
            if let expDate = Date(rfc3339DateTimeString: model.expires) {
                revocation.setValue(expDate, forKeyPath: "expires")
            }
            if let lastUpdated = Date(rfc3339DateTimeString: model.lastUpdated) {
                revocation.setValue(lastUpdated, forKeyPath: "lastUpdated")
            }
            print("-- Added Revocation with KID: \(kidConverted)")
        }
        
        RevocationDataStorage.shared.saveContext()
    }

    func deleteExpiredRevocations(for date: Date) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Revocation")
        let predicate:  NSPredicate = NSPredicate(format: "expires < %@", argumentArray: [date])
        fetchRequest.predicate = predicate
        do {
            let revocations = try managedContext.fetch(fetchRequest)
            revocations.forEach { managedContext.delete($0) }
            print("  Deleted \(revocations.count) revocations for expiredDate: \(date)")
            try managedContext.save()
            ()
        } catch let error as NSError {
            print("Could not fetch revocations. Error: \(error.localizedDescription) for expiredDate: \(date)")
            return
        } catch {
            print("Could not fetch revocations for expiredDate: \(date).")
            return
        }
    }

    func deletePartition(pid: String) {
        guard let object = loadPartitions(pid: pid)?.first else { return }

        // Save the deletions to the persistent store
        managedContext.delete(object)
        do {
            try managedContext.save()
            print("  Deleted partition with id: \(pid)")
        } catch let error as NSError {
            print("Could not save after deleting: \(error.localizedDescription) partition pid: \(pid)")
        } catch {
            print("Could not save after deleting partition pid: \(pid).")
        }
    }
    
    
    func deleteExpiredPartitions(for date: Date) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Partition")
        let predicate:  NSPredicate = NSPredicate(format: "expires < %@", argumentArray: [date])
        fetchRequest.predicate = predicate
        do {
            let partitions = try managedContext.fetch(fetchRequest)
            partitions.forEach { managedContext.delete($0) }
            print("  Deleted \(partitions.count) partitions for expiredDate: \(date)")
            try managedContext.save()
            ()
        } catch let error as NSError {
            print("Could not fetch revocations. Error: \(error.localizedDescription) for expiredDate: \(date)")
            return
        } catch {
            print("Could not fetch revocations for expiredDate: \(date).")
            return
        }
    }

    func deletePartitions(kid: String, x: UInt16?, y: UInt16?, completion: LoadingCompletion) {
        let kidConverted = Helper.convertToBase64url(base64: kid)

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Partition")
        let predicate: NSPredicate
        if x != nil && y != nil {
            predicate = NSPredicate(format: "kid == %@ && x == %d && y == %d", argumentArray: [kidConverted, x!, y!])
            
        } else if x != nil {
            predicate = NSPredicate(format: "kid == %@ && x == %d", argumentArray: [kidConverted, x!])
            
        } else if y != nil {
            predicate = NSPredicate(format: "kid == %@ && y == %d", argumentArray: [kidConverted, y!])
            
        } else {
            predicate = NSPredicate(format: "kid == %@", argumentArray: [kidConverted])
        }
        
        fetchRequest.predicate = predicate
        
         do {
            let partitions = try managedContext.fetch(fetchRequest)
            partitions.forEach { managedContext.delete($0) }
            print("  Deleted \(partitions.count) partitions for kid: \(kid)")
            try managedContext.save()
            completion(nil, nil)
        } catch let error as NSError {
            print("Could not fetch partition: \(error), \(error.userInfo) for kid: \(kid)")
            completion(nil, DataBaseError.dataBaseError(error: error))
        } catch {
            print("Could not fetch partition for kid: \(kid).")
            completion(nil, DataBaseError.loading)
        }
    }
    
    func loadPartitions(pid: String) -> [NSManagedObject]? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Partition")
        let predicate:  NSPredicate = NSPredicate(format: "pid == %@", argumentArray: [pid])
        fetchRequest.predicate = predicate
        
        do {
            let partitions = try managedContext.fetch(fetchRequest)
            print("  Extracted \(partitions.count) partitions for id: \(pid)")
            return partitions
        } catch let error as NSError {
            print("Could not fetch: \(error), \(error.userInfo) for id: \(pid)")
            return nil
        } catch {
            print("Could not fetch for id: \(pid).")
            return nil
        }
    }

    func loadRevocations(kid: String) -> [NSManagedObject]? {
        let kidConverted = Helper.convertToBase64url(base64: kid)

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Revocation")
        let predicate: NSPredicate = NSPredicate(format: "kid == %@", argumentArray: [kidConverted])
        fetchRequest.predicate = predicate
        
        do {
            let revocations = try managedContext.fetch(fetchRequest)
            print("  Extracted \(revocations.count) revocations for id: \(kid)")
            return revocations
        } catch let error as NSError {
            print("Could not fetch: \(error), \(error.userInfo) for id: \(kid)")
            return nil
        } catch {
            print("Could not fetch for id: \(kid).")
            return nil
        }
    }

    func loadPartitions(kid: String, x: UInt16?, y: UInt16?, completion: LoadingCompletion) {
        let kidConverted = Helper.convertToBase64url(base64: kid)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Partition")
        let predicate: NSPredicate
        if x != nil && y != nil {
            predicate = NSPredicate(format: "kid == %@ && x == %d && y == %d", argumentArray: [kidConverted, x!, y!])
            
        } else if x != nil {
            predicate = NSPredicate(format: "kid == %@ && x == %d", argumentArray: [kidConverted, x!])
            
        } else if y != nil {
            predicate = NSPredicate(format: "kid == %@ && y == %d", argumentArray: [kidConverted, y!])
            
        } else {
            predicate = NSPredicate(format: "kid == %@", argumentArray: [kidConverted])
        }
        
        fetchRequest.predicate = predicate
        
        do {
            let partitions = try managedContext.fetch(fetchRequest)
            print("  Extracted \(partitions.count) partitions for kid: \(kid), x: \(x!), y: \(y!)")
            if x != nil && y != nil {
                print("  Extracted \(partitions.count) partitions for kid: \(kid), x: \(x!), y: \(y!)")
            } else if x != nil {
                print("  Extracted \(partitions.count) partitions for kid: \(kid), x: \(x!)")
            } else if y != nil {
                print("  Extracted \(partitions.count) partitions for kid: \(kid), y: \(y!)")
            } else {
                print("  Extracted \(partitions.count) partitions for kid: \(kid)")
            }
            completion(partitions, nil)
            
        } catch let error as NSError {
          print("Could not fetch requested partitions: \(error), \(error.userInfo)")
            completion(nil, DataBaseError.dataBaseError(error: error))
            
        } catch {
            print("Could not fetch requested partitions.")
            completion(nil, DataBaseError.loading)
        }
    }
    
    func createSlice(expDate: String, sliceModel: SliceModel) -> NSManagedObject {
        let sliceEntity = NSEntityDescription.entity(forEntityName: "Slice", in: managedContext)!
        let slice = NSManagedObject(entity: sliceEntity, insertInto: managedContext)
        if let expDate = Date(rfc3339DateTimeString: expDate) {
            slice.setValue(expDate, forKeyPath: "expiredDate")
        }

        slice.setValue(sliceModel.version, forKeyPath: "version")
        slice.setValue(sliceModel.type, forKeyPath: "type")
        slice.setValue(sliceModel.hash, forKeyPath: "hashID")
        return slice
    }

    func createChunks(chunkModels: [String : SliceDict], partition: NSManagedObject) -> NSOrderedSet {
        let chunkSet: NSMutableOrderedSet = []
        for key in chunkModels.keys  {
            let chunkEntity = NSEntityDescription.entity(forEntityName: "Chunk", in: managedContext)!
            let chunk = NSManagedObject(entity: chunkEntity, insertInto: managedContext)
            guard let sliceDict = chunkModels[key] else { return chunkSet }
            let slices: NSMutableOrderedSet = []
            for sliceKey in sliceDict.keys {
                let slice: NSManagedObject = createSlice(expDate: sliceKey, sliceModel: sliceDict[sliceKey]!)
                slice.setValue(chunk, forKeyPath: "chunk")
                slices.add(slice)
            }
            chunk.setValue(key, forKeyPath: "cid")
            chunk.setValue(slices, forKeyPath: "slices")
            chunk.setValue(partition, forKeyPath: "partition")
            chunkSet.add(chunk)
        }
        return chunkSet
    }
    
    func saveTestChunkHashes(forPartitionID pid: String, data: Data) {
        guard let object = loadPartitions(pid: pid)?.first else { return }
        guard let chunks: NSOrderedSet = object.value(forKey: "chunks") as? NSOrderedSet else { return }
        
        for chunkObject in chunks {
            guard let chunk = (chunkObject as? NSManagedObject), let slices: NSOrderedSet = chunk.value(forKey: "slices") as? NSOrderedSet else { continue }
            
            for sliceObject in slices {
                guard let slice = (sliceObject as? NSManagedObject) else { continue }
                let generatedData = data
                slice.setValue(generatedData, forKeyPath: "hashData")
            }
        }
        do {
            try managedContext.save()
            print("  Saved Hashes for part id: \(pid)")
        } catch let error as NSError {
          print("Could not save added hashes: \(error.localizedDescription)")
        } catch {
            print("Could not save new partition.")
        }
    }
    
    func savePartitions(kid: String, models: [PartitionModel]) {
        let kidConverted = Helper.convertToBase64url(base64: kid)

        print("Start saving Partitions for KID: \(kidConverted)")
        let revocation = loadRevocations(kid: kidConverted)?.first

        for model in models {
            let entity = NSEntityDescription.entity(forEntityName: "Partition", in: managedContext)!
            let partition = NSManagedObject(entity: entity, insertInto: managedContext)
            partition.setValue(kidConverted, forKeyPath: "kid")
            partition.setValue(model.id, forKeyPath: "pid")
            if let expDate = Date(rfc3339DateTimeString: model.expires) {
                partition.setValue(expDate, forKeyPath: "expires")
            }

            if let xValue = model.x {
                partition.setValue(UInt16(xValue), forKeyPath: "x")
            }
            
            if let yValue = model.y {
                partition.setValue(UInt16(yValue), forKeyPath: "y")
            }
            
            let chunkParts = createChunks(chunkModels: model.chunks, partition: partition)
            partition.setValue(chunkParts, forKeyPath: "chunks")
            partition.setValue(revocation, forKeyPath: "revocation")
        }
        
        do {
            try managedContext.save()
            print("  Saved Partitions for KID: \(kidConverted)")
        } catch let error as NSError {
          print("Could not save new partition: \(error), \(error.userInfo)")
        } catch {
            print("Could not save new partition.")
        }
    }
}
