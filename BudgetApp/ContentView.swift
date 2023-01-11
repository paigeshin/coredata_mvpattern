//
//  ContentView.swift
//  BudgetApp
//
//  Created by paige shin on 2023/01/11.
//

import SwiftUI

enum SheetAction: Identifiable {
    
    case add
    case edit(BudgetCategory)
    
    var id: Int {
        switch self {
            case .add:
                return 1
            case .edit(_):
                return 2
        }
    }
    
}

struct ContentView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    // MARK: CORE DATA - FETCH DATA 
//    @FetchRequest(sortDescriptors: []) private var budgetCategoryResults: FetchedResults<BudgetCategory>
    @FetchRequest(fetchRequest: BudgetCategory.all) private var budgetCategoryResults: FetchedResults<BudgetCategory>
    @State private var isPresented: Bool = false
    @State private var sheetAction: SheetAction?
    
    private var total: Double {
        self.budgetCategoryResults.reduce(0) { partialResult, budgetCategory in
            return partialResult + budgetCategory.total
        }
    }
    
    // MARK: CORE DATA - DELETE
    private func deleteBudgetCategory(budgetCategory: BudgetCategory) {
        self.viewContext.delete(budgetCategory)
        do {
            try self.viewContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: CORE DATA - EDIT
    private func editBudgetCategory(budgetCategory: BudgetCategory) {
        self.sheetAction = .edit(budgetCategory)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                
                HStack {
                    Text("Total Budget - ")
                    Text(self.total as NSNumber, formatter: NumberFormatter.currency)
                        .fontWeight(.bold)
                } //: HSTACK
                
                BudgetListView(budgetCategoryResults: self.budgetCategoryResults,
                               onDeleteBudgetCategory: { budgetCategory in
                    self.deleteBudgetCategory(budgetCategory: budgetCategory)
                },
                               onEditBudgetCategory: { budgetCategory in
                    self.editBudgetCategory(budgetCategory: budgetCategory)
                })
            } //: VSTACK
            .sheet(item: self.$sheetAction, content: { sheetAction in
                // display the sheet
                switch sheetAction {
                    case .add:
                        AddBudgetCategoryView()
                    case .edit(let budgetCategory):
                        AddBudgetCategoryView(budgetCategory: budgetCategory)
                }
            })
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Category") {
                        self.isPresented = true
                    }
                }
            }
            .padding()
        } //: STACK
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
}
