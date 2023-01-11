//
//  CoreDataManager.swift
//  BudgetApp
//
//  Created by paige shin on 2023/01/11.
//

import Foundation
import CoreData

class CoreDataManager {
    
    static let shared: CoreDataManager = CoreDataManager()
    private var persistentContainer: NSPersistentContainer
    
    private init(){
        self.persistentContainer = NSPersistentContainer(name: "BudgetModel")
        self.persistentContainer.loadPersistentStores { desc, error in
            if let error: Error = error {
                fatalError("Unable to initialize Core Data stacl \(error)")
            }
        }
    }
    
    var viewContext: NSManagedObjectContext {
        self.persistentContainer.viewContext
    }
    
    
}
