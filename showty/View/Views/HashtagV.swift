//
//  HashtagV.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit

class HashtagV: UICollectionReusableView {
    
   
    @IBOutlet weak var latestPicture: RoundImageV!
    @IBOutlet weak var hashtag: UILabel!
    @IBOutlet weak var subscribers: UILabel!
    @IBOutlet weak var subscribeButton: CustomButton!
    
    var latestPictureDimensions: (height: CGFloat, width: CGFloat)?
    var subscribeCallback: (()->())?
    
    
    override func awakeFromNib() {
    
        super.awakeFromNib()
    
        latestPictureDimensions = (latestPicture.bounds.height, latestPicture.bounds.width)
    
    }
    
    @IBAction func subcribe(_ sender: CustomButton) {
        self.subscribeCallback?()
    }
    
}
