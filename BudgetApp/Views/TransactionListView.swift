//
//  TransactionListView.swift
//  BudgetApp
//
//  Created by paige shin on 2023/01/11.
//

import SwiftUI
import CoreData

struct TransactionListView: View {
    
    @FetchRequest var transactions: FetchedResults<Transaction>
    let onDeleteTransaction: (Transaction) -> Void
    
    init(request: NSFetchRequest<Transaction>,
         onDeleteTransaction: @escaping (Transaction) -> Void) {
        self._transactions = FetchRequest(fetchRequest: request)
        self.onDeleteTransaction = onDeleteTransaction
    }
    
    var body: some View {
        if self.transactions.isEmpty {
            Text("No Transactions.")
        } else {
            List {
                ForEach(self.transactions) { transaction in
                    HStack {
                        Text(transaction.title ?? "")
                        Spacer()
                        Text(transaction.total as NSNumber, formatter: NumberFormatter.currency)
                    } //: HSTACK
                } //: FOREACH
                .onDelete { offsets in
                    offsets.map { index in
                        return self.transactions[index]
                    }
                    .forEach { transaction in
                        self.onDeleteTransaction(transaction)
                    }
                }
            } //: LIST
        }
    }
}

