//
//  SocketIOMessager.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import Foundation
import UIKit
import SocketIO

final class SocketIOMessenger{
    
    static let shared = SocketIOMessenger()
    
    private var socket: SocketIOClient?
    private var manager: SocketManager
    private var socketURL = PlistReader.shared.getValue(nameOfFile: "Info", nameOfKey: "SocketIOURL") as! String
    private var startedTypingSent = false
    
    
    deinit{
        
        print("SocketIOMessager deinitialized")
    }
    
    private init() {
        
        manager = SocketManager(socketURL: URL(string: socketURL)!)
        
        manager.config = SocketIOClientConfiguration(arrayLiteral: .extraHeaders(["Authorization" : "Bearer " + Tokens.retrieveTokenFromKeyChain(token_type: "access_token")!]), .compress, .log(true), .forceNew(true))
        socket = manager.defaultSocket
        
        
        print("SocketIOMessager initialized")
        
    }
    
    func reassignToken(completionHandler: @escaping ()->()){
        
        socket?.disconnect()
        manager.disconnect()
        manager.config.insert(.extraHeaders(["Authorization" : "Bearer " + Tokens.retrieveTokenFromKeyChain(token_type: "access_token")!]), replacing: true)
        completionHandler()
    }
    
    
    func establishConnection() {
        
        socket?.connect()
        
    }
    
    
    func getHandlers()->[String]{
        
        
        let handlers = socket?.handlers.map{$0.event}
        return handlers!
        
    }
    
    func removeHandlers(handlers: [UUID]){
        
        let _ = handlers.map{socket?.off(id: $0)}
        
        
    }
    
    func removeAllHandlers(){
        
        socket?.removeAllHandlers()
    }
    
    func closeConnection() {
        
        socket?.disconnect()
        
        
    }
    
    
    
    func sendMessage(sender: String, receiver: String, text: String?, url: String?, completionHandler: @escaping ((CustomMessage?) -> ())){
        
        
        socket?.emitWithAck("chatMessage", sender, receiver, text, url ).timingOut(after: 3, callback: { data in
            
            
            let jsonData = (data[0] as! String).data(using: .utf8)!
            
            let parsingResult = DataParser<CustomMessage>.createModelFromJSONData(data: jsonData)
            
            if parsingResult != nil{
                
                completionHandler(parsingResult)
                
            }else{
                
                completionHandler(nil)
            }
            
            
        })
        
        
    }
    
    func updateReadStatus(msgID: Int, completionHandler: @escaping ((Bool)->())){
        
        socket?.emitWithAck("updateReadStatus", msgID).timingOut(after:5, callback:{data in
            
            let success = data[0] as! Bool
            completionHandler(success)
            
        })
        
        
    }
    
    func socketErrorHandler(completionHandler: @escaping (SocketError) -> ())->UUID{
        
        return socket!.on(clientEvent: .error) { (data, ack) in
            
            
            if let dict = data[0] as? [String:Any]{
                if let unauthorizedError = DataParser<SocketError>.createModelFromDictionary(dict: dict){
                    
                    completionHandler(unauthorizedError)
                }
                
                if let msg = data[0] as? String{
                    
                    print(msg)
                    
                }
            }
            
        }
        
    }
    
    func getConnectedUsers(completionHandler: @escaping ([String]) -> ()) -> UUID {
        
        return socket!.on("connectedUsers") { (dataArray, ack) -> () in
            
            
            if let users = dataArray[0] as? [String]{
                
                completionHandler(users)
                
            }
            ack.with(true)
        }
        
        
    }
    
    func sendConnectedUsersUpdate() {
        
        socket!.emit("connectedUsersUpdate")
        
    }
    
    
    func getChatMessage(completionHandler: @escaping (CustomMessage?) -> ()) -> UUID {
        
        return socket!.on("newChatMessage") { (dataArray, ack) -> () in
            
            
            let sender  = dataArray[0]
            let text = dataArray[1]
            let sentAtRaw = dataArray[2]
            let id = dataArray[3]
            let read = dataArray[4]
            let receiver = dataArray[5]
            let url =  dataArray[6]
            
            let dict = ["sender": sender, "text": text, "id": id, "sentAt": sentAtRaw, "read": read, "receiver": receiver, "url" : url] as [String : Any]
            
            if let textMessage = DataParser<CustomMessage>.createModelFromDictionary(dict: dict){
                completionHandler(textMessage)
                
            }
            
            completionHandler(nil)
            
            
            ack.with(true)
            
        }
        
    }
    
    func getReadMessageID(completionHandler: @escaping (Int) -> ()) -> UUID{
        
        return socket!.on("messageRead"){ (dataArray, ack) -> () in
            
            let id = dataArray[0] as! Int
            
            completionHandler(id)
            
        }
        
        
    }
    
    func getConnectedEvent(completionHandler: @escaping () -> ()) -> UUID{
        
        return  socket!.on(clientEvent: .connect, callback:
                            { (dataArray, ack) in
                                completionHandler()
                            })
    }
    
    func getStartTypingEvent(completionHandler: @escaping () -> ()) -> UUID{
        
        return  socket!.on("userStartedTyping") { (dataArray, ack) in
            
            completionHandler()
        }
        
    }
    
    func getStoppedTypingEvent(completionHandler: @escaping () -> ()) -> UUID{
        
        
        return socket!.on("userStoppedTyping") { (dataArray, ack) in
            
            completionHandler()
        }
        
    }
    
    
    
    func sendStartTypingMessage(receiver: String) {
        
        if !startedTypingSent{
            socket!.emit("startedTyping", receiver)
        }
        startedTypingSent = true
    }
    
    
    func sendStopTypingMessage(receiver: String) {
        socket!.emit("stoppedTyping", receiver)
        startedTypingSent = false
    }
}


extension Optional: SocketData where Wrapped == String{

    public func socketRepresentation() -> SocketData {
        
        guard let unwrapped = self else { return NSNull() }
            return unwrapped
          
       }

}
