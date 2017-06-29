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
        
        switch pal.status {
        case .Available:
            self.stateLabel.text = "Available"
            self.stateImage.image = UIImage(named: "userAvailable")
        case .Occupied:
            self.stateLabel.text = "Occupied"
            self.stateImage.image = UIImage(named: "userOccupied")
        case .Blocked:
            self.stateLabel.text = "Blocked"
            self.stateImage.image = UIImage(named: "userBlocked")
        default:
            print("The pal state can't be represented in cell")
        }
    }

}
