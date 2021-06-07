//
//  PostCell.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import RxSwift



class PostCell: UITableViewCell {
    
    @IBOutlet weak var avatar: RoundImageV!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var descriptionTxt: ActiveLabel!
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var commentBtn: UIButton!
    @IBOutlet weak var moreBtn: UIButton!
    @IBOutlet weak var noLikes: UILabel!
    
    var likeUnlikeCallback: (()->())?
    var commentCallback: (()->())?
    var moreCallback: (()->())?
    var userCallback: (()->())?
    
    
    var avatarDimensions: (height: CGFloat, width: CGFloat)?
    var pictureDimensions: (height: CGFloat, width: CGFloat)?

    override func awakeFromNib() {
        
        super.awakeFromNib()

        avatarDimensions = (avatar.bounds.height, avatar.bounds.width)
        
        pictureDimensions = (picture.bounds.height, picture.bounds.width)
        
        likeBtn.setTitleColor(UIColor.clear, for: UIControl.State())
        
     
    }


    
    @IBAction func like(_ sender: UIButton) {
        
       likeUnlikeCallback?()
    }
    
    @IBAction func comment(_ sender: UIButton) {
        
        commentCallback?()
    }
    
    
    @IBAction func more(_ sender: UIButton) {
        
        moreCallback?()
    }
    
    @IBAction func user(_ sender: UIButton) {
        
        userCallback?()
        
    }
    
}
