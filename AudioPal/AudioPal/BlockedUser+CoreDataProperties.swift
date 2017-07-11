//
//  BlockedUser+CoreDataProperties.swift
//  AudioPal
//
//  Created by Danno on 7/10/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import Foundation
import CoreData


extension BlockedUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlockedUser> {
        return NSFetchRequest<BlockedUser>(entityName: "BlockedUser")
    }

    @NSManaged public var username: String?
    @NSManaged public var uuid: String?

}
