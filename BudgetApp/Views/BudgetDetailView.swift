//
//  BudgetDetailView.swift
//  BudgetApp
//
//  Created by paige shin on 2023/01/11.
//

import SwiftUI
import CoreData

struct BudgetDetailView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    let budgetCategory: BudgetCategory
    
    @State private var title: String = ""
    @State private var total: String = ""
    
    private var isFormValid: Bool {
        guard let totalAsDouble = Double(self.total) else { return false }
        return !self.total.isEmpty && !self.total.isEmpty && totalAsDouble > 0
    }
    
    // MARK: CORE DATA - SAVE, RELATIONSHIP
    private func saveTransaction() {
        do {
            let transaction = Transaction(context: self.viewContext)
            transaction.title = title
            transaction.total = Double(self.total)!
            self.budgetCategory.addToTransactions(transaction) // this method is automatically added with one to many relationship
            try self.viewContext.save()
            
            // reset the title and the total
            self.title = ""
            self.total = "" 
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: CORE DATA - DELETE, RELATIONSHIP
    private func deleteTransaction(_ transaction: Transaction) {
        self.viewContext.delete(transaction)
        do {
            try self.viewContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(self.budgetCategory.title ?? "")
                        .font(.largeTitle)
                    HStack {
                        Text("Budget:")
                        Text(self.budgetCategory.total as NSNumber, formatter: NumberFormatter.currency)
                    } //: HSTACK
                    .fontWeight(.bold)
                    
                } //: VSTACK
            } //: HSTACK
            
            Form {
                Section {
                    TextField("Title", text: self.$title)
                    TextField("Total", text: self.$total)
                } header: {
                    Text("Add Transaction")
                }
                
                HStack {
                    Spacer()
                    Button("Save Transaction") {
                        // Save Transaction
                        self.saveTransaction()
                    }
                    .disabled(!self.isFormValid)
                    .buttonStyle(.bordered)
                    /*
                     Fix Issues
                     https://www.donnywals.com/xcode-14-publishing-changes-from-within-view-updates-is-not-allowed-this-will-cause-undefined-behavior/
                     => add button style
                     */
                    
                    Spacer()
                } //: HSTACK
                
                
            } //: FORM
            .frame(maxHeight: 300)
            .padding([.bottom], 20)
            
            VStack {
                // Display summary of the budget category
                BudgetSummaryView(budgetCategory: self.budgetCategory)
                
                // Display the transaction
                TransactionListView(
                    request: BudgetCategory.transactionByCategoryRequest(self.budgetCategory),
                    onDeleteTransaction: { transaction in
                        self.deleteTransaction(transaction)
                    }
                )
            } //: VSTACK
            
            Spacer()
        } //: VSTACK
        .padding()
    }
}

struct BudgetDetailView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetDetailView(budgetCategory: BudgetCategory())
    }
}
