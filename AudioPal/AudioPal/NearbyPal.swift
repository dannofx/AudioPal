//
//  NearbyPal.swift
//  AudioPal
//
//  Created by Danno on 5/22/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

enum PalStatus: Int {
    case NoAvailable = 0
    case Available
    case Occupied
    case Blocked
}

class NearbyPal: NSObject {
    let identifier: String
    var name: String?
    var status: PalStatus
    
    init(_ identifier: String) {
        self.identifier = identifier
        self.status = .NoAvailable
    }

}
