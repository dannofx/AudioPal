//
//  InfoViewController.swift
//  AudioPal
//
//  Created by Danno on 7/6/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {
    
    @IBOutlet weak var urlButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        urlButton.setTitle(repoURL, for: UIControl.State.normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openURL(_ sender: Any) {
        UIApplication.shared.open(URL(string: repoURL)!, options: [:], completionHandler: nil)
    }
}
