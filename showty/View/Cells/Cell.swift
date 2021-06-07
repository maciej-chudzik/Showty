//
//  Cell.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import RxSwift

class Cell: UICollectionViewCell {
    
    
    @IBOutlet weak var picture: UIImageView!
    
    var pictureDimensions: (height: CGFloat, width: CGFloat)?
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        pictureDimensions = (picture.bounds.height, picture.bounds.width)
    }
  
        
}
