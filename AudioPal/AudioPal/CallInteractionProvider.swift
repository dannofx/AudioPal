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
    fileprivate var incomingCalls: [Call]
    weak var callManager: CallManager?
    
    override init() {
        incomingCalls = []
        callController = CXCallController()
        provider = CXProvider(configuration: type(of: self).createProviderConfiguration())
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    static func createProviderConfiguration() -> CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: "AudioPal")
        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        
        return providerConfiguration
    }
}

// MARK: Actions

extension CallInteractionProvider {

    func startInteraction(withCall call: Call) {
        let handle = CXHandle(type: .generic, value: call.pal.username!)
        let startCallAction = CXStartCallAction(call: call.pal.uuid!,
                                                handle: handle)
        
        startCallAction.isVideo = false
        
        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        requestTransaction(transaction)
    }
    
    func endInteraction(withCall call: Call) {
        let endCallAction = CXEndCallAction(call: call.pal.uuid!)
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)
        requestTransaction(transaction)
    }
    
    func setHeldInteraction(call: Call, onHold: Bool) {
        let setHeldCallAction = CXSetHeldCallAction(call: call.pal.uuid!,
                                                    onHold: onHold)
        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)
        requestTransaction(transaction)
    }
    
    func reportIncomingCall(call: Call, completion: ((NSError?) -> Void)? = nil) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: call.pal.username!)
        update.hasVideo = false
        incomingCalls.append(call)
        provider.reportNewIncomingCall(with: call.pal.uuid!, update: update) { error in
            /*
             Only add incoming call to the app's list of calls if the call was allowed (i.e. there was no error)
             since calls may be "denied" for various legitimate reasons. See CXErrorCodeIncomingCallError.
             */
            if error != nil {
                self.callManager?.endCall(call)
            }
            
            completion?(error as NSError?)
        }
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
}

// MARK: CXProviderDelegate

extension CallInteractionProvider: CXProviderDelegate {
    
    
    func providerDidReset(_ provider: CXProvider) {
        print("Provider did reset")
        
//        guard let call = (callManager?.currentCall) else {
//            return
//        }
//        
//        callManager?.endCall(call)
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        
        action.fulfill()
        
//        // Create & configure an instance of SpeakerboxCall, the app's model class representing the new outgoing call.
//        let call = SpeakerboxCall(uuid: action.callUUID, isOutgoing: true)
//        call.handle = action.handle.value
//        
//        /*
//         Configure the audio session, but do not start call audio here, since it must be done once
//         the audio session has been activated by the system after having its priority elevated.
//         */
//        configureAudioSession()
//        
//        /*
//         Set callback blocks for significant events in the call's lifecycle, so that the CXProvider may be updated
//         to reflect the updated state.
//         */
//        call.hasStartedConnectingDidChange = { [weak self] in
//            self?.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: call.connectingDate)
//        }
//        call.hasConnectedDidChange = { [weak self] in
//            self?.provider.reportOutgoingCall(with: call.uuid, connectedAt: call.connectDate)
//        }
//        
//        // Trigger the call to be started via the underlying network service.
//        call.startSpeakerboxCall { success in
//            if success {
//                // Signal to the system that the action has been successfully performed.
//                action.fulfill()
//                
//                // Add the new outgoing call to the app's list of calls.
//                self.callManager.addCall(call)
//            } else {
//                // Signal to the system that the action was unable to be performed.
//                action.fail()
//            }
//        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        
        guard let callManager = callManager else {
            action.fail()
            return
        }
        
        guard let call = (incomingCalls.filter{ $0.pal.uuid == action.callUUID}.first) else {
            action.fail()
            return
        }
        
        let success = callManager.acceptCall(call)
        if success {
            action.fulfill()
        } else {
            action.fail()
        }
        incomingCalls.removeAll()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        
        guard let callManager = callManager else {
            action.fail()
            return
        }

        guard let call = (incomingCalls.filter{ $0.pal.uuid == action.callUUID}.first) else {
            action.fail()
            return
        }
        
        callManager.endCall(call)
        
        // Signal to the system that the action has been successfully performed.
        action.fulfill()
        incomingCalls.removeAll()

    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
//        // Retrieve the SpeakerboxCall instance corresponding to the action's call UUID
//        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
//            action.fail()
//            return
//        }
//        
//        // Update the SpeakerboxCall's underlying hold state.
//        call.isOnHold = action.isOnHold
//        
//        // Stop or start audio in response to holding or unholding the call.
//        if call.isOnHold {
//            stopAudio()
//        } else {
//            startAudio()
//        }
//        
//        // Signal to the system that the action has been successfully performed.
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("Timed out \(#function)")
        
        // React to the action timeout if necessary, such as showing an error UI.
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("Received \(#function)")
        El audio debe ser configurado aquí
        // Start call audio media, now that the audio session has been activated after having its priority boosted.
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("Received \(#function)")
        
        /*
         Restart any non-call related audio now that the app's audio session has been
         de-activated after having its priority restored to normal.
         */
    }
    
}

