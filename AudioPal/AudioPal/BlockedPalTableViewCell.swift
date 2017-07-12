//
//  BlockedPalTableViewCell.swift
//  AudioPal
//
//  Created by Danno on 7/5/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

protocol BlockedPalTableViewCellDelegate: class {
    func blockedPalCell(_ cell: BlockedPalTableViewCell, didUnblockAt unblockIndex: Int)
}

class BlockedPalTableViewCell: UITableViewCell {
    
    @IBOutlet weak var usernameLabel: UILabel!
    private var index: Int!
    weak var delegate: BlockedPalTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(withBlockedUser blockedUser: BlockedUser, atIndex: Int) {
        usernameLabel.text = blockedUser.username
        index = atIndex
    }
    
    @IBAction func unblockUser(sender: Any) {
        self.delegate?.blockedPalCell(self, didUnblockAt: index)
    }

}
