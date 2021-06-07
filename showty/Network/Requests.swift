//
//  Requests.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import Foundation


struct APICloudinary{
    
    static func uploadImage(imageData: Data) -> CloudinaryCall<CloudinaryImageUploadResponse>{
        return CloudinaryCall(imageData: imageData, uploadPreset: PlistReader.shared.getValue(nameOfFile: "Info", nameOfKey: "CLDUploadPreset") as! String)
    }
}

struct APIMainRequests{
    
    static func test() -> APICall<APIResponseMessage> {
        
        return APICall(method: .get, endpoint: "test")
    }
    

    static func getUser(login: String) -> APICall<User> {
        
        return APICall(method: .get, endpoint: "user/" + "\(login)")
    }
    
    static func updateUser(parameters: [String:Any]) -> APICall<APIResponseMessage> {
        
        return APICall(method: .put, endpoint: "user", parameters: parameters)
    }

    static func register(parameters: [String:Any]) -> APICall<APIResponseMessage> {
        
        return APICall(method: .post, endpoint: "register", parameters: parameters, option: .noTokens)
    }
    
    static func login(login: String, password: String) -> APICall<Tokens> {
        
        return APICall(method: .post, endpoint: "login", parameters: ["login" : login, "password" : password], option: .noTokens)
    }
    
    static func facebookLogin(facebook_access_token: String) -> APICall<APIFacebookLoginResponse>{
        
        return APICall(method: .post, endpoint: "facebooklogin", parameters: ["facebook_access_token": facebook_access_token], option: .noTokens)
    }
    
    static func initialLogout() -> APICall<APIResponseMessage> {
        
        return APICall(method: .delete, endpoint: "logout1")
    }
    
    static func finalLogout() -> APICall<APIResponseMessage> {
        
        return APICall(method: .delete, endpoint: "logout2", option: .onlyRefreshToken)
    }
    
    static func refreshToken() -> APICall<Tokens> {
        
        return APICall(method: .post, endpoint: "refresh", option: .onlyRefreshToken)
        
    }
    
    static func loggedUser() -> APICall<User> {
        
        return APICall(method: .get, endpoint: "loggeduser")
    }
    
    static func publishPost(parameters: [String:Any]) -> APICall<APIResponseMessage> {
        
        return APICall(method: .post, endpoint: "post", parameters: parameters)
        
    }
    
    static func deletePost(post_id: Int) -> APICall<APIResponseMessage> {
        
        return APICall(method: .delete, endpoint: "post/" + "\(post_id)")
        
    }
    
    static func getPosts(login: String, page: Int) -> APICall<Posts> {
        
        return APICall(method: .get, endpoint: "posts/" + "\(login)" + "/" + "\(page)")
        
    }

    static func getNewestPost() -> APICall<Post> {
        
        return APICall(method: .get, endpoint: "post")
        
    }
    
    static func countUserPosts(login: String) -> APICall<Posts> {
        
        return APICall(method: .post, endpoint: "posts/" + "\(login)")
        
    }
    
    static func like(parameters: [String:Any]) -> APICall<APIResponseMessage> {
        
        return APICall(method: .post, endpoint: "like", parameters: parameters)
        
    }
    
    static func countPostsLikes(post_id: Int) -> APICall<Post> {
        
        return APICall(method: .post, endpoint: "likes/" + "\(post_id)")
        
    }
    
    static func checkLike(post_id: Int) -> APICall<APIResponseMessage> {
        
        return APICall(method: .get, endpoint: "like/" + "\(post_id)")
        
    }
    
    static func follow(parameters: [String:Any]) -> APICall<APIResponseMessage> {
        
        return APICall(method: .post, endpoint: "follow", parameters: parameters)
    }
    
    static func checkFollow(follower_login: String, followee_login: String) -> APICall<APIResponseMessage> {
        
        return APICall(method: .get, endpoint: "follow/" + "\(follower_login)" + "/" + "\(followee_login)")
    }
    
    static func getFollows(login: String) -> APICall<Follows> {
        
        return APICall(method: .get, endpoint: "follows/" + "\(login)")
    }
    
    static func comment(parameters: [String:Any]) -> APICall<APIResponseMessage> {
        
        return APICall(method: .post, endpoint: "comment", parameters: parameters)
    }
    
    static func getLatestComment(post_id: Int) -> APICall<Comment> {
        
        return APICall(method: .get, endpoint: "comment/" + "\(post_id)")
    }
    
    static func getComments(post_id: Int) -> APICall<Comments> {
        
        return APICall(method: .get, endpoint: "comments/" + "\(post_id)")
    }
    
    static func search(parameters: [String:Any]) -> APICall<[SearchResult]> {
        
        return APICall(method: .post, endpoint: "search", parameters: parameters)
    }
    
    static func searchUser(parameters: [String:Any]) -> APICall<[SearchResult]> {
        
        return APICall(method: .post, endpoint: "search_user", parameters: parameters)
    }
    
    static func getPostsWithHashtag(parameters: [String:Any]) -> APICall<HashtagPosts> {
        
        return APICall(method: .post, endpoint: "hashtags", parameters: parameters)
        
    }
    
    static func getLatestPostWithHashtag(parameters: [String:Any]) -> APICall<Post> {
        
        return APICall(method: .post, endpoint: "hashtag", parameters: parameters)
        
    }
    
    static func countHashtagSubscribers(hashtag: String) -> APICall<HashtagSubscribers> {
        
        return APICall(method: .get, endpoint: "subscriptions/" + "\(hashtag)" )
    }
    
    static func checkSubscription(hashtag: String, subscriber: String) -> APICall<APIResponseMessage> {
        
        return APICall(method: .get, endpoint: "subscribe/" + "\(hashtag)" + "/" + "\(subscriber)")
    }
    
    static func subscribe(parameters: [String:Any]) -> APICall<APIResponseMessage> {
        
        return APICall(method: .post, endpoint: "subscribe", parameters: parameters)
    }
    
    static func getPostsOfFeed(page: Int, per_page: Int) -> APICall<FeedPosts> {
        
        return APICall(method: .get, endpoint: "feed/" + "\(page)" + "/" + "\(per_page)")
    }
    
    static func getConversations() -> APICall<Conversations> {
        
        return APICall(method: .get, endpoint: "conversations")
    }
    
    static func deleteConversationWith(login: String) -> APICall<CustomMessages> {
        
        return APICall(method: .delete, endpoint: "conversation_with/" + "\(login)" )
    }
    
    static func getUnreadMessagesOfConversation(of first_user: String, with second_user: String) -> APICall<CustomMessages>{
        
        return APICall(method: .get, endpoint: "unread_messages/" + "\(first_user)" + "/" + "\(second_user)")
    }
    
    static func getMessagesOfConversation(of first_user: String, with second_user: String) -> APICall<CustomMessages>{
        
        return APICall(method: .get, endpoint: "messages/" + "\(first_user)" + "/" + "\(second_user)")
    }
  
}
