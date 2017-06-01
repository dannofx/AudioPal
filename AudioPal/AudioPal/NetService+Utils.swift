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
    
    public convenience init(domain: String, type: String, baseName: String, uuid: UUID, port: Int32)
    {
        let customServiceName = "\(uuid.uuidString)|\(baseName)"
        self.init(domain: "\(domain).", type: serviceType, name: customServiceName, port: 0)
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
        let uuidString = elements[0]
        let uuid = NSUUID(uuidString: uuidString)! as UUID
        elements = elements[1].components(separatedBy: " (")
        let base = elements[0]
        var version = 0
        if elements.count == 2 {
            var versionString = elements[1]
            versionString = versionString.replacingOccurrences(of: ")", with: "")
            version = Int(versionString)!
        }
        
        return (base, uuid, version)
    }
}
