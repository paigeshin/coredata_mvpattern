//
//  BudgetSummaryView.swift
//  BudgetApp
//
//  Created by paige shin on 2023/01/11.
//

import SwiftUI

struct BudgetSummaryView: View {
    
    @ObservedObject var budgetCategory: BudgetCategory
    
    var body: some View {
        VStack {
            Text("\(self.budgetCategory.overSpent ? "Overspent" : "Remaining") \(Text(self.budgetCategory.remainingBudgetTotal as NSNumber, formatter: NumberFormatter.currency))")
                .frame(maxWidth: .infinity)
                .fontWeight(.bold)
                .foregroundColor(self.budgetCategory.overSpent ? .red : .green)
            
        } //: VSTACK
    }
}

