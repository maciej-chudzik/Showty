//
//  CustomDateFormatter.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import Foundation

final class CustomDateFormatter{
    
    static let formatter: DateFormatter = {
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        return formatter
    }()
}
