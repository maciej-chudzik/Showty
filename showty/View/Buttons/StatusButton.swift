//
//  StatusButton.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit

class StatusButton: UIButton {
    
    
    let statusDot: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 3
        view.backgroundColor = .green
        return view
    }()
    
    
    var isOnline: Bool = false{
        
        didSet{
            setStatus()
        }
    }
    
    
    func setStatus() {
        statusDot.isHidden = !isOnline
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(statusDot)
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusDot.leftAnchor.constraint(equalTo: leftAnchor, constant: -10),
            statusDot.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            
            statusDot.heightAnchor.constraint(equalToConstant: statusDot.layer.cornerRadius*2),
            statusDot.widthAnchor.constraint(equalToConstant: statusDot.layer.cornerRadius*2)
        ])
        setStatus()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
