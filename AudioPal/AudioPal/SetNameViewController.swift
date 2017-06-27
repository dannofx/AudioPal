//
//  SetNameViewController.swift
//  AudioPal
//
//  Created by Danno on 5/18/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

class SetNameViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var logoContainer: UIView!
    @IBOutlet weak var logoConstraint: NSLayoutConstraint!
    var initialLogoValue: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.isEnabled = false
        nameTextField.delegate = self
        initialLogoValue = logoConstraint.constant
        if logoContainer.frame.origin.y < 0.0 {
            initialLogoValue += logoContainer.frame.origin.y
        }
        addStyle()
        prepareForAnimation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.animatePhase1()
        }

        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation.isPortrait || UIDevice.current.orientation.isFlat {
            self.logoContainer.isHidden = false
        } else {
            self.logoContainer.isHidden = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didChangeText(sender: UITextField) {
        
        startButton.isEnabled = sender.text != ""
        
    }

    @IBAction func startApp(sender: UIButton) {
        
        UserDefaults.standard.setValue(nameTextField?.text, forKey: StoredValues.username)
        let username: String = nameTextField!.text!
        let userInfo: [AnyHashable : Any] = [StoredValues.username: username]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationNames.userReady),
                                        object: self,
                                        userInfo: userInfo)
        self.dismiss(animated: true)
        
    }
    
    @IBAction func hideKeyboard(sender: UIView) {
        self.view.endEditing(true)
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

}

// MARK: - Add style

private extension SetNameViewController {
    func addStyle() {
        // Textfield
        let border = CALayer()
        let width: CGFloat = 2.0
        border.borderColor = UIColor.untLightYellow.cgColor
        let y = nameTextField.frame.height - width
        let frameWidth = nameTextField.frame.width
        border.frame = CGRect(x: 0.0, y: y, width: frameWidth, height: width)
        border.borderWidth = width
        nameTextField.layer.addSublayer(border)
        nameTextField.layer.masksToBounds = false

    }
    
    func prepareForAnimation() {
        self.logoConstraint.constant = -20
        self.startButton.isHidden = true
        self.nameTextField.isHidden = true
        self.nameLabel.isHidden = true
    }
    
    func animatePhase1() {
        self.logoConstraint.constant = self.initialLogoValue
        self.view.setNeedsUpdateConstraints()
        UIView.animate(withDuration: 1.0, animations: {
            self.view.layoutIfNeeded()
        }) { _ in
            self.animatePhase2()
        }
    }
    
    func animatePhase2() {
        UIView.transition(with: self.view,
                          duration: 1.0,
                          options: .transitionCrossDissolve,
                          animations: {
                            self.startButton.isHidden = false
                            self.nameTextField.isHidden = false
                            self.nameLabel.isHidden = false
        })
    }
}
