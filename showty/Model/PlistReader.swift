//
//  PlistReader.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import Foundation

final class PlistReader{

    static let shared = PlistReader()
    
    
    func getValue(nameOfFile: String, nameOfKey: String) -> Any{
        
        let path = Bundle.main.path(forResource: nameOfFile, ofType: "plist")
        let nameOfFile = NSDictionary(contentsOfFile: path!)
        
        return nameOfFile?.object(forKey: nameOfKey) as Any}

}
