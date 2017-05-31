//
//  NetService+Utils.swift
//  AudioPal
//
//  Created by Danno on 5/31/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

extension NetService {
    var baseName: String {
        get {
            let tuple = parseNameData()
            if tuple == nil {
                return ""
            }
            
            return tuple!.base
        }
    }
    
    var uuid: UUID? {
        get {
            let tuple = parseNameData()
            if tuple == nil {
                return nil
            }
            
            return tuple!.uuid
        }
    }
    
    var version: Int {
        let tuple = parseNameData()
        if tuple == nil {
            return -1
        }
        
        return tuple!.version
    }
    
    private func parseNameData() -> (base: String, uuid: UUID, version: Int)? {
        var elements = self.name.components(separatedBy: "|")
        if elements.count < 2 {
            return nil
        }
        let base = elements[0]
        elements = elements[1].components(separatedBy: " (")
        let uuidString = elements[0]
        let uuid = NSUUID(uuidString: uuidString)! as UUID
        var version = 0
        if elements.count == 2 {
            var versionString = elements[1]
            versionString = versionString.replacingOccurrences(of: ")", with: "")
            version = Int(versionString)!
        }
        
        return (base, uuid, version)
    }
}
