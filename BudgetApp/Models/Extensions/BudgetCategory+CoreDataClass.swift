//
//  BudgetCategory+CoreDataClass.swift
//  BudgetApp
//
//  Created by paige shin on 2023/01/11.
//

import Foundation
import CoreData

@objc(BudgetCategory)
public class BudgetCategory: NSManagedObject {
    
    public override func awakeFromInsert() {
        self.dateCreated = Date()
    }
    
    var overSpent: Bool {
        self.remainingBudgetTotal < 0
    }
    
    var transactionsTotal: Double {
        self.transactionsArray.reduce(0) { partialResult, transaction in
            return partialResult + transaction.total
        }
    }
    
    var remainingBudgetTotal: Double {
        return self.total - self.transactionsTotal
    }
    
    static var all: NSFetchRequest<BudgetCategory> {
        let request = BudgetCategory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
        return request
    }
    
    private var transactionsArray: [Transaction] {
        guard let transactions = transactions else { return [] }
        let allTransactions = (transactions.allObjects as? [Transaction]) ?? []
        return allTransactions.sorted { t1, t2 in
            return t1.dateCreated! > t2.dateCreated!
        }
    }
    
    static func byId(_ id: NSManagedObjectID) -> BudgetCategory {
        let viewContext = CoreDataManager.shared.viewContext
        guard let budgetCategory = viewContext.object(with: id) as? BudgetCategory else {
            fatalError("Id not found")
        }
        return budgetCategory
    }
    
    static func transactionByCategoryRequest(_ budgetCategory: BudgetCategory) -> NSFetchRequest<Transaction> {
        let request = Transaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
        request.predicate = NSPredicate(format: "category = %@", budgetCategory)
        return request
    }
    
}
