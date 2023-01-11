//
//  Transaction+CoreDataClass.swift
//  BudgetApp
//
//  Created by paige shin on 2023/01/11.
//

import Foundation
import CoreData

@objc(Transaction)
public class Transaction: NSManagedObject {
    
    public override func awakeFromInsert() {
        self.dateCreated = Date()
    }
    
}
