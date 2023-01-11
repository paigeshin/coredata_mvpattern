//
//  NumberFormatter+Extensions.swift
//  BudgetApp
//
//  Created by paige shin on 2023/01/11.
//

import Foundation

extension NumberFormatter {
    
    static var currency: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }
    
}
