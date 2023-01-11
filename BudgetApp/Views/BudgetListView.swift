//
//  BudgetListView.swift
//  BudgetApp
//
//  Created by paige shin on 2023/01/11.
//

import SwiftUI

struct BudgetListView: View {
    
    let budgetCategoryResults: FetchedResults<BudgetCategory>
    let onDeleteBudgetCategory: (BudgetCategory) -> Void
    let onEditBudgetCategory: (BudgetCategory) -> Void
    
    var body: some View {
        List {
            
            if !self.budgetCategoryResults.isEmpty {
                ForEach(self.budgetCategoryResults) { budgetCategory in
                    NavigationLink(value: budgetCategory) {
                        HStack {
                            Text(budgetCategory.title ?? "")
                            Spacer()
                            VStack(alignment: .trailing, spacing: 10) {
                                Text(budgetCategory.total as NSNumber, formatter: NumberFormatter.currency)
                                Text("\(budgetCategory.overSpent ? "Overspent" : "Remaining") \(Text(budgetCategory.remainingBudgetTotal as NSNumber, formatter: NumberFormatter.currency))")
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .fontWeight(.bold)
                                    .foregroundColor(budgetCategory.overSpent ? .red : .green)
                            } //: VSTACK
                        } //: HSTACK
                        .contentShape(Rectangle())
                        .onLongPressGesture {
                            self.onEditBudgetCategory(budgetCategory)
                        }
                    } //: LINK
                } //: FOREACH
                .onDelete { indexSet in
                    indexSet.map { index in
                        return self.budgetCategoryResults[index]
                    }
                    .forEach { budgetCategory in
                        self.onDeleteBudgetCategory(budgetCategory)
                    }
                }
            } else {
                Text("No budget categories exist.")
            }
        } //: LIST
        .listStyle(.plain)
        .navigationDestination(for: BudgetCategory.self) { budgetCategory in
            BudgetDetailView(budgetCategory: budgetCategory)
        }
    } //: BODY
        
}

