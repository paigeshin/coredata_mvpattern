# CoreData

### Preparation

1. Create File (Data Model) 
2. Create Entity 
3. CodeGen ⇒ Category/Extension 

### CoreData Extension

- BudgetCategory+CoreDataClass

```swift
import Foundation
import CoreData

@objc(BudgetCategory)
public class BudgetCategory: NSManagedObject {
    
    public override func awakeFromInsert() {
        self.dateCreated = Date()
    }
    
}
```

### CoreData Manager

- PersistentContainer name must match file name of your `Data Model`

```swift
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
```

### Inject CoreData ViewContext

```swift
import SwiftUI

@main
struct BudgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
        }
    }
}
```

# Model + Core Data Extensions 

### BudgetCategory+CoreDataClass

```swift
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

```

### Transacion+CoreDataClass

```swift
import Foundation
import CoreData

@objc(Transaction)
public class Transaction: NSManagedObject {
    
    public override func awakeFromInsert() {
        self.dateCreated = Date()
    }
    
}

```

# Views 

### App

```swift
@main
struct BudgetAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
        }
    }
}

```

### ContentView

```swift
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

```

### AddBudgetCategoryView

```swift
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

```

### BudgetListView

```swift
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


```

### BudgetDetailView

```swift
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

```

### TransactionListView

```swift
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


```

### BudgetSummaryView

```swift
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


```
