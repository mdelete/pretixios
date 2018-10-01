//
//  Event+CoreDataProperties.swift
//  pretixios
//
//  Created by Marc Delling on 01.10.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//
//

import Foundation
import CoreData


extension Event {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Event> {
        return NSFetchRequest<Event>(entityName: "Event")
    }

    @NSManaged public var slug: String?
    @NSManaged public var name: String?

}
