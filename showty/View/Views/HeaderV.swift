//
//  HeaderV.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import RxSwift

class HeaderV: UICollectionReusableView {
    
    @IBOutlet weak var avatar: RoundImageV!
    @IBOutlet weak var noPosts: UILabel!
    @IBOutlet weak var noFollowers: UILabel!
    @IBOutlet weak var noFollowees: UILabel!
    @IBOutlet var noLabels: [UILabel]!
    @IBOutlet weak var postsLbl: UILabel!
    @IBOutlet weak var followersLbl: UILabel!
    @IBOutlet weak var followingsLbl: UILabel!
    @IBOutlet weak var fullname: UILabel!
    @IBOutlet weak var descriptionTxtV: UITextView!
    @IBOutlet weak var button: CustomButton!
    
    
    
    var editCallback: (()->Void)?
    var followCallback: (()->Void)?
    var bag = DisposeBag()
    
    var userFollowedUnfollowed = PublishSubject<Bool>()
    
    var avatarDimensions: (height: CGFloat, width: CGFloat)?
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        avatarDimensions = (avatar.bounds.height, avatar.bounds.width)
        
    }
    
    
    @IBAction func edit(_ sender: Any) {
        self.editCallback?()
    }
    
    @IBAction func follow(_ sender: Any) {
        
        self.followCallback?()
    }
    
}
 
        

        

