//
//  NSManagedObject+FirstLetter.swift
//  pretixios
//
//  Created by Marc Delling on 10.09.17.
//  Copyright © 2017 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit
import CoreData

class Stats {
    @objc static func fetchCount(for entityName: String, predicate: NSPredicate, with managedObjectContext: NSManagedObjectContext) -> Int {
        
        var count: Int = 0
        
        managedObjectContext.performAndWait {
            
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
            fetchRequest.predicate = predicate
            fetchRequest.resultType = NSFetchRequestResultType.countResultType
            
            do {
                count = try managedObjectContext.count(for: fetchRequest)
            } catch {
                let fetchError = error as NSError
                print("Unable to Perform Count")
                print("\(fetchError), \(fetchError.localizedDescription)")
            }
            
        }
        
        return count
    }
}

extension NSManagedObject {

    @objc func uppercaseFirstLetterOfName() -> String {
        self.willAccessValue(forKey: "uppercaseFirstLetterOfName")
        
        var result = "#"
        
        if let name = self.value(forKey: "attendee_name") as? String, name.count > 0 {
            result = String(name[name.startIndex]).uppercased()
        }
        
        self.didAccessValue(forKey: "uppercaseFirstLetterOfName")
        
        return result
    }
    
}

extension NSFetchedResultsController {
    
    @objc func tryFetch() {
        do {
            try self.performFetch()
        } catch {
            print("Unable to Perform Fetch Request in \(#file) \(#function), Line: \(#line)")
            print("\(error), \(error.localizedDescription)")
        }
    }
    
}
