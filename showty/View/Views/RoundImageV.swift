//
//  RoundImageV.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit

class RoundImageV: UIImageView {

    override func awakeFromNib() {
        
        super.awakeFromNib()
        self.layer.cornerRadius = self.frame.size.height / 2
        self.clipsToBounds = true
        
    }

}
