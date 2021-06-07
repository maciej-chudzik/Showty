//
//  CommentCell.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {
    
    
    @IBOutlet weak var avatar: RoundImageV!
    @IBOutlet weak var login: UILabel!
    @IBOutlet weak var comment: ActiveLabel!
    @IBOutlet weak var time: UILabel!
    
    
    var avatarDimensions: (height: CGFloat, width: CGFloat)?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        avatarDimensions = (avatar.bounds.height, avatar.bounds.width)
  
  
    }
    


        

}
