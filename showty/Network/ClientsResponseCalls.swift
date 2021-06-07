//
//  ClientsResponseCalls.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import Foundation
import UIKit


final class CloudinaryCall<T> {
    
    let imageData: Data?
    let uploadPreset: String?
    let url: String?
    let decode: (Data)  throws -> T?
    
    
    init(imageData: Data? = nil, uploadPreset: String? = nil, url: String? = nil, decode: @escaping (Data) throws -> T?) {
        
        self.imageData = imageData
        self.uploadPreset = uploadPreset
        self.decode = decode
        self.url = url
    }
    
}

extension CloudinaryCall where T: Decodable{
    
    
    convenience init(imageData: Data, uploadPreset: String){
        
        self.init ( imageData: imageData, uploadPreset: uploadPreset, url: nil, decode: { data in
            
            try JSONDecoder().decode(T.self, from: data)
        })
    }
    
}

extension CloudinaryCall where T == UIImage{
    
    
    convenience init(url: String){
        
        self.init ( imageData: nil, uploadPreset: nil, url: url, decode: { data in

            T(data: data)
            
        })
    }
    
}




extension CloudinaryCall where T == Void {
    
    convenience init(imageData: Data, uploadPreset: String){
        
        self.init (imageData: imageData, uploadPreset: uploadPreset, decode: {_ in ()})
    }
    
}

enum CallOption{
    
    case onlyRefreshToken
    case noTokens
    
}

final class APICall<T> {
    let method: Method
    let endpoint: String
    let parameters: [String:Any]?
    let option: CallOption?
    let decode: (Data) -> T
    
    init(method: Method = .get, endpoint: String, parameters: [String:Any]? = nil, option: CallOption? = nil ,decode: @escaping (Data)  -> T) {
        
        self.method = method
        self.endpoint = endpoint
        self.parameters = parameters
        self.option = option
        self.decode = decode
    }
    
}
extension APICall where T: Decodable {
    convenience init(method: Method = .get, endpoint: String, parameters: [String:Any]? = nil, option: CallOption? = nil) {
        self.init(method: method, endpoint: endpoint, parameters: parameters, option: option, decode: {data in
            try! JSONDecoder().decode(T.self, from: data)
        })
    }
}
    
extension APICall where T == Void {
    convenience init(method: Method = .get, endpoint: String, parameters: [String:Any]? = nil,option: CallOption? = nil) {
        self.init(method: method, endpoint: endpoint, parameters: parameters, option: option, decode: { _ in () }
        )
    }
}


enum Method {
    case get, post, put, patch, delete
}




