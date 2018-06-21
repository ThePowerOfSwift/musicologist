//
//  SongCell.swift
//  Musicologist
//
//  Created by Robert Mogos on 24/05/2018.
//  Copyright © 2018 Algolia. All rights reserved.
//

import UIKit

class SongCell: UITableViewCell {

  @IBOutlet weak var headerLabel: UILabel!
  @IBOutlet weak var songView: UIImageView!
  @IBOutlet weak var footLabel: UILabel!
  override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
