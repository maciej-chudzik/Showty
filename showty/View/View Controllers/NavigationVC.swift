//
//  NavigationVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit

class NavigationVC: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.tintColor = .label
        self.navigationBar.barTintColor = .systemBackground
        self.navigationBar.isTranslucent = false
       
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    

    
}
