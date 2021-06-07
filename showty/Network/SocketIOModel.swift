//
//  SocketIOModel.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import Foundation
import MessageKit

struct Sender: SenderType{
    var senderId: String
    
    var displayName: String
    
    init(senderId: String, displayName: String){
        self.senderId = senderId
        self.displayName = displayName
        
    }
    
}

struct Receiver: ReceiverType{
    var receiverId: String
    
    var displayName: String
    
    init(receiverId: String, displayName: String){
        self.receiverId = receiverId
        self.displayName = displayName
        
    }
    
}


struct Message: MessageTypeExtended{
    
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var read: Bool
    var receiver: ReceiverType
    

    init(sender: SenderType, messageId: String, sentDate: Date, kind: MessageKind, read: Bool, receiver: ReceiverType) {
        
        self.sender = sender
        self.messageId = messageId
        self.sentDate = sentDate
        self.kind = kind
        self.read = read
        self.receiver = receiver
        
    }

}

struct CustomMessage: Codable, Equatable{
    
    var id: Int
    var sender: String
    var receiver: String
    var text: String?
    var sentAt: String
    var read: Bool
    var url: String?
    
    init(id: Int, sender: String, receiver: String, text: String, sentAt: String, read: Bool , url: String) {
        
        self.id = id
        self.sender = sender
        self.receiver = receiver
        self.text = text
        self.sentAt = sentAt
        self.read = read
        self.url = url
        
    }
    
    static func == (lhs: CustomMessage, rhs: CustomMessage) -> Bool {
        if lhs.id == rhs.id && lhs.sender == rhs.sender && lhs.receiver == rhs.receiver && lhs.text == rhs.text && lhs.sentAt == rhs.sentAt && lhs.read == rhs.read && lhs.url == rhs.url {
            return true
        }else{
            return false
        }
    }
    
}

extension CustomMessage{
    
    func ToMessageTypeExtended() -> MessageTypeExtended{
        
        if self.url != nil{
            
            let pictureItem = PictureItem(url: URL(string: self.url!), image: nil, placeholderImage: UIImage(), size: CGSize(width: 100, height: 100))
            
            return Message(sender: Sender(senderId: self.sender, displayName: self.sender), messageId: String(self.id), sentDate: CustomDateFormatter.formatter.date(from: self.sentAt)!, kind: .photo(pictureItem), read: self.read, receiver: Receiver (receiverId: self.receiver, displayName:self.receiver))
            
        }
        
        return Message(sender: Sender(senderId: self.sender, displayName: self.sender), messageId: String(self.id), sentDate: CustomDateFormatter.formatter.date(from: self.sentAt)!, kind: .text( self.text!), read: self.read, receiver: Receiver (receiverId: self.receiver, displayName:self.receiver))
        
    }
    
    
    
}

struct CustomMessages: Codable{
    
    var messages: [CustomMessage]?
    
}

struct Conversation: Codable, Equatable{
    
    var with: String?
    var latest_message: CustomMessage?
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        if lhs.with == rhs.with && lhs.latest_message == rhs.latest_message{
            return true
        }else{
            return false
        }
    }
    
    init(with: String, latest_message: CustomMessage){
        self.with = with
        self.latest_message = latest_message
        
    }
    
}

struct Conversations: Codable{
    
    var conversations: [Conversation]?
  
}

struct PictureItem: MediaItem{
    
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(url: URL?, image: UIImage?, placeholderImage: UIImage, size: CGSize){
        
        self.url = url
        self.image = image
        self.placeholderImage = placeholderImage
        self.size = size

    }
    
}

protocol MessageTypeExtended: MessageType {
    
    var read: Bool {get set}
    var receiver: ReceiverType {get}
}



protocol ReceiverType {

    var receiverId: String { get }
    var displayName: String { get }
}

struct SocketErrorData: Codable{
    
    
    var code: String
    var message: String
    var type: String
    
    init(code: String, message: String, type: String){
        self.code = code
        self.message = message
        self.type = type
        
    }
    
}
struct SocketError: Codable{
    
    var data: SocketErrorData
    var message: String
    
    
}
