//
//  AddBudgetCategoryView.swift
//  BudgetApp
//
//  Created by paige shin on 2023/01/11.
//

import SwiftUI

struct AddBudgetCategoryView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var total: Double = 0
    @State private var messages: [String] = []
    private var budgetCategory: BudgetCategory?
    
    init(budgetCategory: BudgetCategory? = nil) {
        self.budgetCategory = budgetCategory
    }
    
    private var isFormValid: Bool {
        if self.title.isEmpty {
            self.messages.append("Title is required")
        }
        
        if self.total <= 0 {
            self.messages.append("Total should be greater than 1")
        }
        
        return self.messages.count == 0
    }
    
    // MARK: CORE DATA - SAVE OR UPDATE
    private func saveOrUpdate() {
        if let budgetCategory: BudgetCategory {
            // update the existing budget category
            // get the budget that you need to update
            let budgetCategory = BudgetCategory.byId(budgetCategory.objectID)
            budgetCategory.title = self.title
            budgetCategory.total = self.total
        } else {
            let budgetCategory = BudgetCategory(context: self.viewContext)
            budgetCategory.title = self.title
            budgetCategory.total = self.total
        }
        
        // save the context
        do {
            try self.viewContext.save()
            self.dismiss()
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: self.$title)
                Slider(value: self.$total, in: 0...500, step: 50) {
                    Text("Total")
                } minimumValueLabel: {
                    Text("$0")
                } maximumValueLabel: {
                    Text("$500")
                }
                
                Text(self.total as NSNumber, formatter: NumberFormatter.currency)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                ForEach(self.messages, id: \.self) { message in
                    Text(message)
                }
                
            } //: FORM
            .onAppear(perform: {
                if let budgetCategory: BudgetCategory {
                    self.title = budgetCategory.title ?? ""
                    self.total = budgetCategory.total
                }
            })
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if self.isFormValid {
                            self.saveOrUpdate()
                        }
                    }
                }
            }
        } //: STACK
    }
}

struct AddBudgetCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        AddBudgetCategoryView()
    }
}
