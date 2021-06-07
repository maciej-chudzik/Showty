//
//  NetworkModel.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import Foundation
import KeychainSwift

struct Tokens: Decodable{
    
    
    var access_token: String?
    var refresh_token: String?
    
    func saveTokenToKeyChain(token_type: String) -> Bool{
        let keychain = KeychainSwift()
        
        switch token_type{
        case "access_token":
            return keychain.set(self.access_token!, forKey: token_type)
            
        case "refresh_token":
            return keychain.set(self.refresh_token!, forKey: token_type)
            
        default:
            return false
            
        }
        
    }
    
    static func retrieveTokenFromKeyChain(token_type: String) -> String?{
        
        let keychain = KeychainSwift()
        return keychain.get(token_type)
    }
    
    static func deleteTokensFromKeyChain() -> Bool{
        let keychain = KeychainSwift()
        return keychain.clear()
    }
    
}

struct APIFacebookLoginResponse: Decodable{
    
    var tokens: Tokens?
    var mergeable: Bool?
    var user: User?
    
}

struct APIResponseMessage: Decodable{
    
    var message: String?
    
}

struct CloudinaryImageUploadResponse: Decodable{
    
    var url: String?
    var public_id: String?
    
}

enum APIResponseMessageText: String{
    
    case followed =  "user followed"
    case unfollowed =  "user unfollowed"
    case subscribed = "hashtag subscribed"
    case unsubscribed = "hashtag unsubscribed"
    case liked = "liked"
    case unliked = "unliked"
    
}

enum APIServerError: Error, Decodable {
    
    case apiResponseError(message: String)
    
    init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodableKeys.self)
        if let api_response_error = try? values.decode(String.self, forKey: .message) {
            self = .apiResponseError(message: api_response_error)
            return
        }
        
        throw CodingError.decoding("Decoding Failed. \(dump(values))")
    }
    enum CodableKeys: String, CodingKey { case message }
    enum CodingError: Error { case decoding(String)}
  
}

extension APIServerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .apiResponseError(let message):
            return NSLocalizedString(message, comment: "")
        }
    }
    
}
