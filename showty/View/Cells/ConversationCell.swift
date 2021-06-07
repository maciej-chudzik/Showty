//
//  ConversationCell.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit

class ConversationCell: UITableViewCell {
    
    @IBOutlet weak var avatar: RoundImageV!
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    
    var avatarDimensions: (height: CGFloat, width: CGFloat)?
    
    enum OnlineStatus{
        
        case online
        case offline
        
    }
    
    func setOnlineStatusRing(status: OnlineStatus){
        
        switch status {
        
        case .online:
                
         
            avatar.layer.borderColor = UIColor.green.cgColor
            avatar.layer.borderWidth = 2.0
      
                
        case .offline:
                
            avatar.layer.borderWidth = 0.0
        }
        
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        

        avatarDimensions = (avatar.bounds.height, avatar.bounds.width)
        
    }



}
