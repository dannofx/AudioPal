//
//  SetNameViewController.swift
//  AudioPal
//
//  Created by Danno on 5/18/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

class SetNameViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField?
    @IBOutlet weak var startButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        startButton?.isEnabled = false
        nameTextField?.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didChangeText(sender: UITextField) {
        
        startButton?.isEnabled = sender.text != ""
        
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
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
