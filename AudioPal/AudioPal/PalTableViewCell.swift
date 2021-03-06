//
//  PalTableViewCell.swift
//  AudioPal
//
//  Created by Danno on 5/30/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

class PalTableViewCell: UITableViewCell {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var stateImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(withPal pal: NearbyPal) {
        self.usernameLabel.text = pal.username
        
        if pal.isBlocked {
            self.stateLabel.text = NSLocalizedString("Blocked", comment: "")
            self.stateImage.image = UIImage(named: "userBlocked")
            return
        }
        
        switch pal.status {
        case .Available:
            self.stateLabel.text =  NSLocalizedString("Available", comment: "")
            self.stateImage.image = UIImage(named: "userAvailable")
        case .Occupied:
            self.stateLabel.text =  NSLocalizedString("Occupied", comment: "")
            self.stateImage.image = UIImage(named: "userOccupied")
        default:
            print("The pal state can't be represented in cell")
        }
    }

}
