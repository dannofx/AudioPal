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
    var uuid: UUID?
    var username: String?
    var status: PalStatus
    var service: NetService!
    
    init(_ service: NetService) {
        self.service = service
        self.status = .NoAvailable
    }

}
