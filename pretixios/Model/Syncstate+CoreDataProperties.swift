//
//  Syncstate+CoreDataProperties.swift
//  pretixios
//
//  Created by Marc Delling on 19.07.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//
//

import Foundation
import CoreData


extension Syncstate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Syncstate> {
        return NSFetchRequest<Syncstate>(entityName: "Syncstate")
    }

    @NSManaged public var lasterror: Int16
    @NSManaged public var lastsync: Date?
    @NSManaged public var path: String
    @NSManaged public var retry: Int16

}
