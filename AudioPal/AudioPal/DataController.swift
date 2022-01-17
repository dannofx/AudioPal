//
//  DataController.swift
//  AudioPal
//
//  Created by Danno on 7/11/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit
import CoreData

protocol DataControllerDelegate: AnyObject {
    func dataController(_ dataController: DataController, didUnblockUserWithId uuid: UUID)
}

class DataController: NSObject {
    
    let persistentContainer: NSPersistentContainer
    weak var delegate: DataControllerDelegate?
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    override init() {
        persistentContainer = NSPersistentContainer(name: "AudioPal")
        super.init()
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                print("An error occurred loading persistent store \(error)")
            }
        }
        subscribeToChanges()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Changes management

private extension DataController {
    func subscribeToChanges() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: self.persistentContainer.viewContext,
                                               queue: nil,
                                               using: managedObjectContextObjectsDidChange)
    }
    
    func managedObjectContextObjectsDidChange(notification: Notification) -> Void {
        guard let userInfo = notification.userInfo else { return }
        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<BlockedUser>, deletes.count > 0 {
            if let delegate = delegate {
                for blockedUser in deletes {
                    if let uuid = UUID(uuidString: blockedUser.uuid!) {
                        delegate.dataController(self, didUnblockUserWithId: uuid)
                    }
                }
            }
        }
    }
}

// MARK: - Blocked users management
private extension DataController {
    
    func insertBlockedPal(_ pal: NearbyPal) {
        persistentContainer.performBackgroundTask { context in
            let blockedUser = NSEntityDescription.insertNewObject(forEntityName: String(describing: BlockedUser.self), into: context) as! BlockedUser
            blockedUser.uuid = pal.uuid!.uuidString
            blockedUser.username = pal.username!
            self.saveContext(context: context)
        }
    }
    
    func deleteBlockedPal(_ pal: NearbyPal) {
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

// MARK: - Client methods

extension DataController {
    
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
            insertBlockedPal(pal)
        } else {
            deleteBlockedPal(pal)
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
    
    func createFetchedResultController() -> NSFetchedResultsController<BlockedUser> {
        let fetchRequest: NSFetchRequest<BlockedUser> = BlockedUser.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: #keyPath(BlockedUser.username), ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                 managedObjectContext: persistentContainer.viewContext,
                                                                 sectionNameKeyPath: nil,
                                                                 cacheName: nil)
        do {
            try fetchedResultController.performFetch()
        } catch let error {
            print("Error fetching blocked users: \(error.localizedDescription)")
        }
        
        return fetchedResultController
        
    }
}
