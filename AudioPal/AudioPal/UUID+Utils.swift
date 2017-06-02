//
//  UUID+Utils.swift
//  AudioPal
//
//  Created by Danno on 6/1/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

extension UUID {
    
    var data: Data {
        get {
            var uuid_bytes = self.uuid
            let uuid_data = withUnsafePointer(to: &uuid_bytes) { (unsafe_uuid) -> Data in
                Data(bytes: unsafe_uuid, count: MemoryLayout<uuid_t>.size)
            }
            return uuid_data
        }
    }
    
    init?(data: Data) {
        if  data.count < MemoryLayout<uuid_t>.size {
            return nil
        }
        var uuid_bytes: uuid_t = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
        let uuid_p1: UnsafePointer<Data> = data.withUnsafeBytes { $0 }
        let uuid_p2: UnsafeMutablePointer<uuid_t> = withUnsafeMutablePointer(to: &uuid_bytes) { $0 }
        memcpy(uuid_p2, uuid_p1, MemoryLayout<uuid_t>.size)
        self.init(uuid: uuid_bytes)
    }
    
}
