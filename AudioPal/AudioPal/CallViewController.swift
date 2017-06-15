//
//  CallViewController.swift
//  AudioPal
//
//  Created by Danno on 6/14/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

class CallViewController: UIViewController, CallManagerDelegate {
    
    @IBOutlet var username_label: UILabel!
    @IBOutlet var message_label: UILabel!
    @IBOutlet var mute_button: UIButton!
    @IBOutlet var hang_button: UIButton!
    @IBOutlet var speaker_button: UIButton!
    var lastStatus: CallStatus!
    weak var callManager: CallManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        lastStatus = .dialing
        callManager?.delegate = self
        updateState()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func updateState() {
        guard let status = callManager?.currentCall?.callStatus else {
            return
        }
        
        switch (status) {
        case .dialing, .presented:
            updateToDialingState()
        case .onCall:
            updateToOnCallState()
        case .responding:
            updateToRespondingState()
        }
        
        lastStatus = status
    }
    
    func updateToDialingState() {
        hang_button.isHidden = false
        mute_button.isHidden = true
        speaker_button.isHidden = true
    }
    
    func updateToOnCallState() {
        hang_button.isHidden = false
        mute_button.isHidden = false
        speaker_button.isHidden = false
    }
    
    func updateToRespondingState() {
        hang_button.isHidden = false
        mute_button.isHidden = true
        speaker_button.isHidden = true
    }
    

}

extension CallViewController {
    @IBAction func toggleMute(sender: UIButton) {
        
    }
    
    @IBAction func hangUp(sender: UIButton) {
        guard let callManager = callManager else {
            return
        }
        
        guard let call = callManager.currentCall else {
            return
        }
        
        callManager.endCall(call)
    }
    
    @IBAction func toggleSpeaker(sender: UIButton) {
        
    }
}

// MARK: - CallManagerDelegate

extension CallViewController {
    func callManager(_ callManager: CallManager, didStartCall call: Call) {
        updateState()
    }
    
    func callManager(_ callManager: CallManager, didEstablishCall call: Call) {
        updateState()
    }
    
    func callManager(_ callManager: CallManager, didEndCall call: Call, error: Error?) {
        // Is therea way to know if it's a rejected call?
        self.dismiss(animated: true)
    }
    
    func callManager(_ callManager: CallManager, didMute: Bool, call: Call) {
        
    }
    
    func callManager(_ callManager: CallManager, didActivateSpeaker: Bool, call: Call) {
        
    }
}
