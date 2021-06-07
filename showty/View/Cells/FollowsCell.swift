//
//  FollowsCell.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit


class FollowsCell: UITableViewCell {
    
    
    @IBOutlet weak var avatar: RoundImageV!
    @IBOutlet weak var login: UILabel!
    @IBOutlet weak var followBtn: CustomButton!
    
    var followCallback: (()->Void)?
    var userCallback: (()->Void)?
    
    var avatarDimensions: (height: CGFloat, width: CGFloat)?
    


    override func awakeFromNib() {
        super.awakeFromNib()

        avatarDimensions = (avatar.bounds.height, avatar.bounds.width)
        
        login.isUserInteractionEnabled = true
        login.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(user(_:))))
    }
    
    
    @objc func user(_ sender: UITapGestureRecognizer) {
        
        self.userCallback?()

    }
    
    @IBAction func follow(_ sender: Any) {
        
        self.followCallback?()
        
    }
    
        
}


