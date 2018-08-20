//
//  Item+CoreDataProperties.swift
//  pretixios
//
//  Created by Marc Delling on 20.08.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//
//

import Foundation
import CoreData

extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var id: Int32
    @NSManaged public var name: String?

}
