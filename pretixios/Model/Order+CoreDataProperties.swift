//
//  Guest+CoreDataProperties.swift
//  pretixios
//
//  Created by Marc Delling on 19.07.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//
//

import Foundation
import CoreData


extension Order {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Order> {
        return NSFetchRequest<Order>(entityName: "Order")
    }
    
    var status : PretixOrderResponse.Result.Status {
        get { return PretixOrderResponse.Result.Status(rawValue: self.status_value) ?? .n }
        set { self.status_value = newValue.rawValue }
    }

    @NSManaged public var attendee_email: String?
    @NSManaged public var attendee_name: String?
    @NSManaged public var checkin: Date?
    @NSManaged public var checkin_attention: Bool
    @NSManaged public var company: String?
    @NSManaged public var datetime: Date?
    @NSManaged public var guid: String?
    @NSManaged public var item: Int32
    @NSManaged public var position: Int32
    @NSManaged public var order: String
    @NSManaged public var secret: String
    @NSManaged public var voucher: NSNumber?
    @NSManaged public var status_value: String
    @NSManaged public var synced: Int16
    @NSManaged public var synctime: Date?
    @NSManaged public var variation: NSNumber?
    @NSManaged public var checkin_list: Int32

}
