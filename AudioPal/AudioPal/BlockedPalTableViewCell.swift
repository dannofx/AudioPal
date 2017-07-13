//
//  BlockedPalTableViewCell.swift
//  AudioPal
//
//  Created by Danno on 7/5/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit
import CoreData

protocol BlockedPalTableViewCellDelegate: class {
    func blockedPalCell(_ cell: BlockedPalTableViewCell, didUnblock objectID: NSManagedObjectID)
}

class BlockedPalTableViewCell: UITableViewCell {
    
    @IBOutlet weak var usernameLabel: UILabel!
    private var objectID: NSManagedObjectID!
    weak var delegate: BlockedPalTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(withBlockedUser blockedUser: BlockedUser) {
        usernameLabel.text = blockedUser.username
        objectID = blockedUser.objectID
    }
    
    @IBAction func unblockUser(sender: Any) {
        self.delegate?.blockedPalCell(self, didUnblock: objectID)
    }
    
    deinit {
        objectID = nil
    }

}
