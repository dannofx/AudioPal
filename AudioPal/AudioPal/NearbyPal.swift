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
    
    class func isAscendant(_ pal1: NearbyPal, _ pal2: NearbyPal) -> Bool{
        if pal1.status == pal2.status {
            guard let username1 = pal1.username else {
                return true
            }
            guard let username2 = pal2.username else {
                return false
            }
            return username1.lowercased() < username2.lowercased()
        } else {
            return pal1.status.rawValue < pal2.status.rawValue
        }
    }

}
