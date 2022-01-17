//
//  UUID+Utils.swift
//  AudioPal
//
//  Created by Danno on 6/1/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

extension UUID {
    
    #if true
    var UInt8Array: [UInt8] {
        let (u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, u16) = self.uuid
        return [u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, u16]
    }
    
    var data: Data {
        return Data(self.UInt8Array)
    }
    #else
    var data: Data {
        get {
            // Based on https://stackoverflow.com/a/41598602
            let uuidTuple = self.uuid
            let uuidBytes = Mirror(reflecting: uuidTuple).children.map({$0.1 as! UInt8})
            let uuidData = Data(uuidBytes)
            return uuidData
        }
    }
    #endif
    
    init?(data: Data) {
        guard data.count == MemoryLayout<uuid_t>.size else {
            return nil
        }
        
        let optionalUUID = data.withUnsafeBytes { byteBuffer -> UUID? in
            guard let pointer = byteBuffer.bindMemory(to: uuid_t.self).baseAddress?.pointee else {
                return nil
            }
            
            return UUID(uuid: pointer)
        }
        
        guard let uuid = optionalUUID else {
            return nil
        }
        
        self = uuid
    }
    
}
