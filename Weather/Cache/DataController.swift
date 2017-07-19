//
//  DataController.swift
//  Weather
//
//  Created by Maarut Chandegra on 18/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation
import CoreData

class DataController
{
    private let model: NSManagedObjectModel
    private let coordinator: NSPersistentStoreCoordinator
    private let dbURL: URL
    private let persistingContext: NSManagedObjectContext
    
    let mainThreadContext: NSManagedObjectContext
    
    init?(withModelName modelName: String)
    {
        guard let modelUrl = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            NSLog("Unable to find model in bundle")
            return nil
        }
        guard let model = NSManagedObjectModel(contentsOf: modelUrl) else {
            NSLog("Unable to create object model")
            return nil
        }
        guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            NSLog("Unable to obtain Documents directory for user")
            return nil
        }
        self.model = model
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        dbURL = docsDir.appendingPathComponent("\(modelName).sqlite")
        
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.name = "Persisting"
        persistingContext.persistentStoreCoordinator = coordinator
        
        mainThreadContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainThreadContext.name = "Main"
        mainThreadContext.parent = persistingContext
        
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL,
                options: options)
        }
        catch let error as NSError {
            log(error: error, abort: true)
        }
    }
    
    func save()
    {
        mainThreadContext.performAndWait {
            if self.mainThreadContext.hasChanges {
                do { try self.mainThreadContext.save() }
                catch let error as NSError { log(error: error, abort: true) }
            }
        }
        persistingContext.perform {
            if self.persistingContext.hasChanges {
                do { try self.persistingContext.save() }
                catch let error as NSError { log(error: error, abort: true) }
            }
        }
    }
    
    func allIcons(context c: NSManagedObjectContext? = nil) -> NSFetchedResultsController<Icon>
    {
        let context = c ?? mainThreadContext
        let request: NSFetchRequest<Icon> = Icon.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: context,
            sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func icon(withId id: String) -> Icon?
    {
        let fetchRequest = NSFetchRequest<Icon>(entityName: "Icon")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        do {
            let results = try self.mainThreadContext.fetch(fetchRequest)
            return results.first
        }
        catch let error as NSError {
            log(error: error, abort: true)
        }
        return nil
    }
    
    func delete(_ icon: Icon)
    {
        mainThreadContext.perform {
            self.mainThreadContext.delete(icon)
            self.save()
        }
    }
    
    func savedLocations(context c: NSManagedObjectContext? = nil) -> NSFetchedResultsController<SavedLocation>
    {
        let context = c ?? mainThreadContext
        let request: NSFetchRequest<SavedLocation> = SavedLocation.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: true)]
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: context,
            sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func delete(_ savedLocation: SavedLocation)
    {
        mainThreadContext.perform {
            self.mainThreadContext.delete(savedLocation)
            self.save()
        }
    }
}

private func log(error: NSError, abort: Bool)
{
    var errorString = "Core Data Error: \(error.localizedDescription)\n\(error)\n"
    if let detailedErrors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
        detailedErrors.forEach { errorString += "\($0.localizedDescription)\n\($0)\n" }
    }
    if abort { fatalError(errorString) }
    else { NSLog(errorString) }
    
}
