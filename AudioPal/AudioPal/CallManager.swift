//
//  CallManager.swift
//  AudioPal
//
//  Created by Danno on 5/22/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

protocol CallManagerDelegate: class {
    func callManager(_ callManager: CallManager, didDetectNearbyPal pal: NearbyPal)
    func callManager(_ callManager: CallManager, didDetectDisconnection pal: NearbyPal)
    func callManager(_ callManager: CallManager, didDetectCallError error:Error, withPal pal: NearbyPal)
    func callManager(_ callManager: CallManager, didPal pal: NearbyPal, changeStatus status: PalStatus)
}

class CallManager: NSObject {
    weak var delegate: CallManagerDelegate?
    
    override init() {
        
    }
    
    public func start() {
        
    }
    
    public func stop() {
        
    }

}
