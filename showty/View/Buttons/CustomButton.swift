//
//  CustomButton.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit

class CustomButton: UIButton {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 5
        self.clipsToBounds = true
    }

}
