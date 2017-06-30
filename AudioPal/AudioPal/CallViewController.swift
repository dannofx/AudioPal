//
//  CallViewController.swift
//  AudioPal
//
//  Created by Danno on 6/14/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

let mediumScreenWidth: CGFloat = 375.0
let smallScreenWidth: CGFloat = 320.0

class CallViewController: UIViewController, CallManagerDelegate {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var hangButton: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    // Constraints
    @IBOutlet var buttonDiameters: [NSLayoutConstraint]!
    @IBOutlet weak var bottomSpace: NSLayoutConstraint!
    @IBOutlet weak var topSpace: NSLayoutConstraint!
    @IBOutlet weak var labelsSpace: NSLayoutConstraint!
    @IBOutlet var buttonSpaces: [NSLayoutConstraint]!
    // UI values
    var buttonSapceVal: CGFloat!
    // Call variables
    weak var callManager: CallManager?
    fileprivate var startCallDate: Date?
    fileprivate var callTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        accomodatePhoneControls()
        callManager?.delegate = self
        updateState()
        view.setNeedsUpdateConstraints()
        view.layoutIfNeeded()
        usernameLabel.text = callManager?.currentCall?.pal.username ?? ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
}

// MARK: - UIControls position

extension CallViewController {
    func accomodatePhoneControls() {
        let width = self.view.bounds.size.width
        if width <= smallScreenWidth {
            accomodateForSmallScreen()
        } else if width <= mediumScreenWidth {
            accomodateForMediumScreen()
        }
        accomodateButtonsToFirstPosition()
    }
    
    func accomodateForSmallScreen() {
        for constraint in buttonDiameters {
            constraint.constant = 68.0
        }
        bottomSpace.constant = 67.0
        topSpace.constant = 52.0
        labelsSpace.constant = 1.0
        usernameLabel.font = UIFont.init(name: usernameLabel.font.fontName, size: 27.0)
        messageLabel.font = UIFont.init(name: messageLabel.font.fontName, size: 16.0)
    }
    
    func accomodateForMediumScreen() {
        bottomSpace.constant = 47.0
        topSpace.constant = 61.0
        labelsSpace.constant = 6.0
    }
    
    func accomodateButtonsToFirstPosition() {
        buttonSapceVal = buttonSpaces.first!.constant
        for space in buttonSpaces {
            space.constant = buttonDiameters.first!.constant * -1
        }
    }
}

// MARK: - Status updates

extension CallViewController {
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
    }
    
    func updateToDialingState() {
        hangButton.isHidden = false
        muteButton.isHidden = true
        speakerButton.isHidden = true
        messageLabel.text = "Ringing..."
    }
    
    func updateToOnCallState() {
        hangButton.isHidden = false
        muteButton.isHidden = false
        speakerButton.isHidden = false
        for space in buttonSpaces {
            space.constant = buttonSapceVal
        }
        view.setNeedsLayout()
        UIView.animate(withDuration: 1.0) { 
            self.view.layoutIfNeeded()
        }
        startCallDate = Date()
        callTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                         target: self,
                                         selector: #selector(updateCallTime),
                                         userInfo: nil,
                                         repeats: true)
        updateCallTime()
        
    }
    
    func updateToRespondingState() {
        hangButton.isHidden = true
        muteButton.isHidden = true
        speakerButton.isHidden = true
        messageLabel.text = "Connecting..."
    }
    
    func updateCallTime() {
        let timeString = stringInterval(forDate: startCallDate)
        messageLabel.text = "AudioPal Audio \(timeString)"
    }
    
    func stringInterval(forDate date: Date?) -> String {
        guard let date = date else {
            return "00:00"
        }
        let interval = Int(Date().timeIntervalSince(date))
        let seconds = interval % 60
        let minutes = ( interval / 60 )
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension CallViewController {
    @IBAction func hangUp(sender: UIButton) {
        guard let callManager = callManager else {
            return
        }
        
        guard let call = callManager.currentCall else {
            return
        }
        
        callManager.endCall(call)
    }
    
    @IBAction func toggleMute(sender: UIButton) {
        guard let callManager = callManager else {
            return
        }
        callManager.toggleMute()
        guard let currentCall = callManager.currentCall else {
            return
        }
        if currentCall.isMuted {
            muteButton.setImage(#imageLiteral(resourceName: "mute_active"), for: .normal)
        } else {
            muteButton.setImage(#imageLiteral(resourceName: "mute"), for: .normal)
        }

    }
    
    @IBAction func toggleSpeaker(sender: UIButton) {
        guard let callManager = callManager else {
            return
        }
        callManager.toggleSpeaker()
        guard let currentCall = callManager.currentCall else {
            return
        }
        if currentCall.useSpeakers {
            speakerButton.setImage(#imageLiteral(resourceName: "speaker_active"), for: .normal)
        } else {
            speakerButton.setImage(#imageLiteral(resourceName: "speaker"), for: .normal)
        }
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
        callTimer?.invalidate()
        callTimer = nil
        self.dismiss(animated: true)
    }
    
    func callManager(_ callManager: CallManager, didMute: Bool, call: Call) {
        
    }
    
    func callManager(_ callManager: CallManager, didActivateSpeaker: Bool, call: Call) {
        
    }
}
