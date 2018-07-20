//
//  Checkinlist+CoreDataProperties.swift
//  pretixios
//
//  Created by Marc Delling on 19.07.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//
//

import Foundation
import CoreData


extension Checkinlist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Checkinlist> {
        return NSFetchRequest<Checkinlist>(entityName: "Checkinlist")
    }

    @NSManaged public var id: Int32
    @NSManaged public var name: String?
    @NSManaged public var checkin_count: Int32
    @NSManaged public var position_count: Int32

}
