//
//  Voucher+CoreDataProperties.swift
//  pretixios
//
//  Created by Marc Delling on 19.07.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//
//

import Foundation
import CoreData


extension Voucher {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Voucher> {
        return NSFetchRequest<Voucher>(entityName: "Voucher")
    }

    @NSManaged public var allow_ignore_quota: Bool
    @NSManaged public var block_quota: Bool
    @NSManaged public var code: String?
    @NSManaged public var comment: String?
    @NSManaged public var id: Int32
    @NSManaged public var item: Int32
    @NSManaged public var max_usages: Int32
    @NSManaged public var price_mode: NSObject?
    @NSManaged public var quota: Int32
    @NSManaged public var redeemed: Int32
    @NSManaged public var subevent: Int32
    @NSManaged public var tag: String?
    @NSManaged public var valid_until: Date?
    @NSManaged public var value: String?
    @NSManaged public var variation: Int32
    @NSManaged public var synced: Int16
    @NSManaged public var synctime: Date?

}
