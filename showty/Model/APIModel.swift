//
//  Message.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import Foundation
import RxSwift





struct User: Decodable, Equatable{
    
    
    var login: String?
    var fullname: String?
    var email: String?
    var description: String?
    var image_id: String?
    var image_height: Int?
    var image_width: Int?
    var telephone: String?
    var gender: String?
    
    static func == (lhs: User, rhs: User) -> Bool {
        if lhs.login == rhs.login && lhs.fullname == rhs.fullname &&  lhs.email == rhs.email && lhs.description == rhs.description && lhs.image_id == rhs.image_id && lhs.image_height == rhs.image_height && lhs.image_width == rhs.image_width && lhs.telephone == rhs.telephone && lhs.gender == rhs.gender {
            return true
        }else{
            
            return false
        }
    }
 
}


struct Post: Decodable{
    
    var post_id: Int?
    var image_id: String?
    var image_height: Int?
    var image_width: Int?
    var login: String?
    var description: String?
    var date: String?
    var likes: [Like]?
    var likes_count: Int?
   
}

struct Comment: Decodable{
    
    var comment_id: Int?
    var post_id: Int?
    var login: String?
    var comment: String?
    var comment_date: String?
    
}



struct SearchResult: Codable{
    
    var search_result: String?
    var type: String?
    
}

struct HashtagPosts: Decodable{
    
    var posts_with_hashtag: [Post]?
}

struct FeedPosts: Decodable{
    
    var posts_of_feed: [Post]?
}


struct Comments: Decodable{
    
    var comments: [Comment]?
}

struct Like: Decodable{
    
    var login: String?
}


struct Follows: Decodable{
    
    var followers: [String]?
    
    var followees: [String]?

}

struct HashtagSubscribers: Decodable{
    
    var subscribers_count: Int?
}


struct Posts: Decodable{
    
    var posts_count: Int?
    
    var posts_user: [Post]?
     
}

enum ViewControllerType{
    
    case followers
    case followees
    
}

enum FollowsType{
    
    case followers
    case followees
}
