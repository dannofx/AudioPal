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

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(withPal pal: NearbyPal) {
        self.usernameLabel.text = pal.username
    }

}
