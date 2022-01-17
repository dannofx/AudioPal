//
//  UICallProvider.swift
//  AudioPal
//
//  Created by Danno on 6/7/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import Foundation
import UIKit
import CallKit
import AVFoundation
import AudioToolbox

class CallInteractionProvider: NSObject {
    fileprivate let provider: CXProvider
    fileprivate let callController: CXCallController
    fileprivate var calls: [Call]
    weak var callManager: CallManager?
    
    override init() {
        calls = []
        callController = CXCallController()
        provider = CXProvider(configuration: type(of: self).createProviderConfiguration())
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    static func createProviderConfiguration() -> CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: "AudioPal")
        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        let icon = #imageLiteral(resourceName: "appiconsmall")
        providerConfiguration.iconTemplateImageData = icon.pngData()
        
        return providerConfiguration
    }
    
    deinit {
        provider.invalidate()
    }
}

// MARK: Actions

extension CallInteractionProvider {

    func startInteraction(withCall call: Call) {
        let handle = CXHandle(type: .generic, value: call.pal.username!)
        let startCallAction = CXStartCallAction(call: call.uuid,
                                                handle: handle)
        startCallAction.isVideo = false
        calls.append(call)
        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        requestTransaction(transaction)
    }
    
    func endInteraction(withCall call: Call) {
        let endCallAction = CXEndCallAction(call: call.uuid)
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)
        requestTransaction(transaction)
    }
    
    func setHeldInteraction(call: Call, onHold: Bool) {
        let setHeldCallAction = CXSetHeldCallAction(call: call.uuid,
                                                    onHold: onHold)
        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)
        requestTransaction(transaction)
    }
    
    func reportIncomingCall(call: Call, completion: ((NSError?) -> Void)? = nil) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: call.pal.username!)
        update.hasVideo = false
        update.supportsUngrouping = false
        update.supportsHolding = false
        update.supportsGrouping = false
        calls.append(call)
        provider.reportNewIncomingCall(with: call.uuid, update: update) { error in
            if error != nil {
                self.endCall(call)
            }
            completion?(error as NSError?)
        }
    }
    
    func reportOutgoingCall(call: Call) {
        provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: nil)
        provider.reportOutgoingCall(with: call.uuid, connectedAt: nil)
    
    }
    
    private func requestTransaction(_ transaction: CXTransaction) {
        callController.request(transaction) { error in
            if let error = error {
                print("Error requesting transaction: \(error)")
            } else {
                print("Requested transaction successfully")
            }
        }
    }
    
    fileprivate func endCall(_ call: Call) {
        call.interactionEnded = true
        if !call.ended {
            self.callManager?.endCall(call)
        }
    }
}

// MARK: CXProviderDelegate

extension CallInteractionProvider: CXProviderDelegate {
    
    
    func providerDidReset(_ provider: CXProvider) {
        
//        guard let call = (callManager?.currentCall) else {
//            return
//        }
//        
//        callManager?.endCall(call)
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        
        guard let callManager = callManager else {
            action.fail()
            return
        }
        
        guard let call = (calls.filter{ $0.uuid == action.callUUID}.first) else {
            action.fail()
            return
        }
        
        let success = callManager.prepareOutgoingCall(call)
        if success {
            action.fulfill()
        } else {
            action.fail()
        }
        
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        
        guard let callManager = callManager else {
            action.fail()
            return
        }
        
        guard let call = (calls.filter{ $0.uuid == action.callUUID}.first) else {
            action.fail()
            return
        }
        
        let success = callManager.acceptIncomingCall(call)
        if success {
            action.fulfill()
        } else {
            action.fail()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        
        guard let call = (calls.filter{ $0.uuid == action.callUUID}.first) else {
            action.fail()
            return
        }
        endCall(call)
        calls.removeAll()
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("Timed out \(#function)")
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {

        callManager?.currentCall?.startAudioProcessing()
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("Received \(#function)")
        
    }
    
}

