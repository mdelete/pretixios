//
//  PretixdroidGuest+CoreDataProperties.swift
//  pretixios
//
//  Created by Marc Delling on 01.05.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//
//

import Foundation
import CoreData


extension PretixdroidGuest {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PretixdroidGuest> {
        return NSFetchRequest<PretixdroidGuest>(entityName: "Pretixdroid")
    }

    @NSManaged public var allowed: Bool
    @NSManaged public var attention: Bool
    @NSManaged public var item: String
    @NSManaged public var name: String
    @NSManaged public var order: String
    @NSManaged public var paid: Bool
    @NSManaged public var redeemed: Bool
    @NSManaged public var secret: String
    @NSManaged public var variation: String?

}
