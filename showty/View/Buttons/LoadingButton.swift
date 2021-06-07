//
//  LoadingButton.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit

class LoadingButton: UIButton {
        
        @IBInspectable var indicatorColor : UIColor = .white
        
        private var originalButtonText: String?
        private var activityIndicator: UIActivityIndicatorView!
    
    
        override func awakeFromNib() {
            super.awakeFromNib()
    
            self.layer.cornerRadius = 5
            self.clipsToBounds = true
            
        }
        
        func showLoading() {
            originalButtonText = self.titleLabel?.text
            self.setTitle("", for: .normal)
            
            if (activityIndicator == nil) {
                activityIndicator = createActivityIndicator()
            }
            
            showSpinning()
        }
        
        func hideLoading() {
            DispatchQueue.main.async(execute: {
                self.setTitle(self.originalButtonText, for: .normal)
                self.activityIndicator.stopAnimating()
            })
        }
        
        private func createActivityIndicator() -> UIActivityIndicatorView {
            let activityIndicator = UIActivityIndicatorView()
            activityIndicator.hidesWhenStopped = true
            activityIndicator.color = indicatorColor
            return activityIndicator
        }
        
        private func showSpinning() {
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(activityIndicator)
            centerActivityIndicatorInButton()
            activityIndicator.startAnimating()
        }
        
        private func centerActivityIndicatorInButton() {
            let xCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: activityIndicator, attribute: .centerX, multiplier: 1, constant: 0)
            self.addConstraint(xCenterConstraint)
            
            let yCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: activityIndicator, attribute: .centerY, multiplier: 1, constant: 0)
            self.addConstraint(yCenterConstraint)
        }
        
    }



