//
//  DataController.swift
//  AudioPal
//
//  Created by Danno on 7/11/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit
import CoreData

class DataController: NSObject {
    
    let persistentContainer: NSPersistentContainer
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    override init() {
        persistentContainer = NSPersistentContainer(name: "AudioPal")
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            
            if let error = error {
                print("An error occurred loading persistent store \(error)")
            }
        }
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        saveContext(context: context)
    }
    
    func saveContext(context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                fatalError("Failure to save context: \(error)")
            }
        }
    }
    
    func checkIfBlocked(pal: NearbyPal, completion: @escaping (_ pal: NearbyPal, _ blocked: Bool) -> ()) {
        
        guard let palUuid = pal.uuid else {
            return
        }
        
        persistentContainer.performBackgroundTask { backgroundContext in
            let request = NSFetchRequest<NSNumber>(entityName: String(describing: BlockedUser.self))
            request.predicate = NSPredicate(format: "uuid == %@", palUuid.uuidString)
            request.resultType = .countResultType
            do  {
                let results = try backgroundContext.fetch(request) 
                let found = results.first!.intValue > 0
                self.persistentContainer.viewContext.perform {
                    completion(pal, found)
                }
                
            } catch {
                print("Error fetching blocked user result")
            }
        }
    }
    
    func updateBlockStatus(pal: NearbyPal) {
        
        if (pal.isBlocked) {
            insertBlockedUser(pal: pal)
        } else {
            deleteBlockedUser(pal: pal)
        }
    }
    
    private func insertBlockedUser(pal: NearbyPal) {
        persistentContainer.performBackgroundTask { context in
            let blockedUser = NSEntityDescription.insertNewObject(forEntityName: String(describing: BlockedUser.self), into: context) as! BlockedUser
            blockedUser.uuid = pal.uuid!.uuidString
            blockedUser.username = pal.username!
            self.saveContext(context: context)
        }
    }
    
    private func deleteBlockedUser(pal: NearbyPal) {
        persistentContainer.performBackgroundTask { context in
            var blockedUser: BlockedUser!
            let request = NSFetchRequest<BlockedUser>(entityName: String(describing: BlockedUser.self))
            request.predicate = NSPredicate(format: "uuid == %@", pal.uuid!.uuidString)
            do  {
                let results = try context.fetch(request)
                if results.count > 0 {
                    blockedUser = results.first!
                } else {
                    return
                }
                
            } catch {
                print("Error fetching blocked user result")
                return
            }
            
            context.delete(blockedUser)
            self.saveContext(context: context)
        }
    }

}
