//
//  SearchCell.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit

class SearchCell: UITableViewCell {
    
    @IBOutlet weak var item: UILabel!
    @IBOutlet weak var avatar: RoundImageV!
    
    
    var avatarDimensions: (height: CGFloat, width: CGFloat)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarDimensions = (avatar.bounds.height, avatar.bounds.width)
    }


}
