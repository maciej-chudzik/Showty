//
//  ConversationsVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import RxSwift

class ConversationsVC: UITableViewController {
    
    var conversations = [Conversation]()
    var statuses = [Bool]()
    var pushMessageToChildVC: ((MessageTypeExtended)->())?
    
    var apiMainClient = APIMainClient()
    var apiCloudinaryClient = APICloudinaryClient()
    let bag = DisposeBag()
    
    var toDeleteConversationIndexPath: IndexPath?
    
    
    @IBAction func dissmiss(_ sender: Any) {
        self.dismiss(animated: true, completion: { [weak self] in
            
            self?.disconnectFromSocketIO()
        })
    }
    
    deinit {
        print("ConversationsVC deinitialized")
        NotificationCenter.default.removeObserver(self)
        SocketIOMessenger.shared.removeAllHandlers()
        
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ConversationsVC initialized")

        NotificationCenter.default.addObserver(self,selector:#selector(connectToSocketIO), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self,selector:#selector(disconnectFromSocketIO), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        
        let _ = addEventHandlers()
        
        loadConversations {
            self.connectToSocketIO()
        }
        
    }
    
    
    private func setStatuses(connectedUsers: [String])->[Int]{
        
        var modifiedIndices = [Int]()
        
        for i in 0..<conversations.count{
            
            if statuses[i] == true{
                
                modifiedIndices.append(i)
            }
            statuses[i] = false
            
            for connectedUser in connectedUsers{
                
                if conversations[i].with! == connectedUser{
                    
                    if statuses[i] == false{
                        
                        modifiedIndices.append(i)
                    }
                    
                    statuses[i] = true

                }
            }
        }
        
        return modifiedIndices
    }
    

    private func addEventHandlers()->[UUID]{
        
        return [SocketIOMessenger.shared.socketErrorHandler{[weak self] error in
            
            
            if error.message == "jwt expired"{
                
                
                _ = self?.apiMainClient.request(APIMainRequests.refreshToken())
                
                .subscribe { (downloadingTokens) in
                    switch downloadingTokens {
                    case .success(let tokens):
                        if tokens.saveTokenToKeyChain(token_type: "access_token"){
                            
                            SocketIOMessenger.shared.reassignToken{
                                SocketIOMessenger.shared.establishConnection()
                                
                            }
                        }
                        
                    case .failure(let error):
                        
                        UIHelper.displayAlert(viewController: self!, message: error.localizedDescription)
                        return
                        
                    }}
                    
                    .disposed(by: self!.bag)

            }
        },SocketIOMessenger.shared.getConnectedUsers(){  [weak self] connectedUsers in
            
            print(connectedUsers)
            let modifiedInices = self?.setStatuses(connectedUsers: connectedUsers)
            let modifiedIndexPaths = modifiedInices!.map{IndexPath(row: $0, section: 0)}
            
            for modifiedIndexPath in modifiedIndexPaths{
                
                let cell = self?.tableView.cellForRow(at: modifiedIndexPath) as! ConversationCell
                
                if self!.statuses[modifiedIndexPath.row] == true{
                    
                    self?.tableView.beginUpdates()
                    
                    cell.setOnlineStatusRing(status: .online)
                    
                    self?.tableView.endUpdates()
                }else{
                    
                    self?.tableView.beginUpdates()
                    
                    cell.setOnlineStatusRing(status: .offline)
                    
                    self?.tableView.endUpdates()
                }
                
            }
            
        },SocketIOMessenger.shared.getConnectedEvent {
            
            SocketIOMessenger.shared.sendConnectedUsersUpdate()
            
        },SocketIOMessenger.shared.getChatMessage(){ [weak self] textMessage in
            
            if let textMessage = textMessage{
                
                
                self?.pushMessageToChildVC?(textMessage.ToMessageTypeExtended())
                
                self?.insertRawMessageToConverstations(textMessage: textMessage)
                
            }
        }]
        
    }
    
    private func insertRawMessageToConverstations(textMessage: CustomMessage){
        
        var exisitingConversationFound = false
        
        for i in self.conversations.indices{
    
            if self.conversations[i].with! == textMessage.sender || self.conversations[i].with! == textMessage.receiver{
                
                exisitingConversationFound = true
                
                
                self.conversations[i].latest_message =  textMessage
                
                if i == 0{
                    
                    DispatchQueue.main.async {

                        self.tableView.performBatchUpdates({
                            self.tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .bottom)}, completion: nil)
                    }
                    
                }else{
                    
                    DispatchQueue.main.async {
                        
                        self.tableView.performBatchUpdates({
                            
                            self.tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .bottom)
                            
                        }, completion: {completed in
                            
                            if completed {
                                self.tableView.moveRow(at: IndexPath(row: i, section: 0), to: IndexPath(row: 0, section: 0))
                                let toMove = self.conversations.remove(at: i)
                                self.conversations.insert(toMove, at: 0)
                                
                            }
                        })

                    }
                    
                }
                
            }
            
            if !exisitingConversationFound {
                
                self.conversations.insert(Conversation(with: textMessage.sender, latest_message: textMessage), at: 0)
                self.statuses.insert(false, at: 0)
                
                self.tableView.performBatchUpdates({
                    
                    
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
                    
                }, completion: nil)
    
            }
            
        }
        
    }
    
    
    
    @objc private func connectToSocketIO() {
        SocketIOMessenger.shared.establishConnection()
        print("connected")
    }
    
    
    
    @objc private func disconnectFromSocketIO() {
        SocketIOMessenger.shared.closeConnection()
        print("disconnected")
    }
    
    
    private func loadConversations(completion: @escaping ()->()){

        _ = apiMainClient.request(APIMainRequests.getConversations())
            
            .subscribe { (loadingConversations) in
                switch loadingConversations {
                case .success(let conversations):
                    
                    
                    self.conversations = conversations.conversations!
                    
                    self.statuses = Array(repeating: false, count: conversations.conversations!.count)
                    
                    completion()
                    
                    DispatchQueue.main.async {
                        
                        self.tableView.reloadData()
                        
                    }
                    
                case .failure(let error):
                    
                    print(error.localizedDescription)
                }
  
            }
            .disposed(by: bag)
    }
    
    private func updateReadStatus(id: Int){
        
        for i in self.conversations.indices{
            
            if self.conversations[i].latest_message?.id == id {
                
                self.conversations[i].latest_message?.read = true
                
                self.tableView.performBatchUpdates({
                    
                    self.tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .fade)
                    
                }, completion: nil)
                
            }
            
        }
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return conversations.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath) as! ConversationCell
        
        if conversations.count > 0{
            
            var font = UIFont()
            
            if conversations[indexPath.row].latest_message!.sender == UserDefaults.standard.value(forKey: "host") as! String{
                
                font = UIFont.systemFont(ofSize: 17.0)
                
            }else{
                
                if (conversations[indexPath.row].latest_message!.read){
                    
                    font = UIFont.systemFont(ofSize: 17.0)
                    
                }else{
                    font = UIFont.boldSystemFont(ofSize: 17.0)
                }
 
            }
            
            if statuses[indexPath.row] == true{
                
                cell.setOnlineStatusRing(status: .online)
            }else{
                
                cell.setOnlineStatusRing(status: .offline)
            }

            cell.loginLabel.font = font
            cell.lastMessageLabel.font = font
            
            cell.loginLabel.text = conversations[indexPath.row].with
            cell.lastMessageLabel.text = conversations[indexPath.row].latest_message?.text
            
            
            if !conversations.isEmpty && cell.tag == indexPath.item{
                
                _ = apiMainClient.request(APIMainRequests.getUser(login: conversations[indexPath.row].with!)).flatMap { (user) -> Single<UIImage> in
                    
                    if user.image_id != nil {
                        
                        let pictureSize = UIHelper.calculatePixelSizeToDownload(imageViewHeight: cell.avatarDimensions!.height, imageViewWidth: cell.avatarDimensions!.width, imageHeight: user.image_height!, imageWidth: user.image_width!)
                        
                        let url = self.apiCloudinaryClient.generateResizedImageUrl(height: pictureSize.height, width: pictureSize.width, publicID: user.image_id!)
                        
                        
                        return self.apiCloudinaryClient.downloadImage(call: CloudinaryCall(url: url))
                        
                        
                        
                    }else{
                        
                        let image = UIImage(named: "avatar.png")
                        
                        return Single.just(image!)
                        
                    }
                }
                
                
                .subscribe {(gettingImage)  in
                    
                    switch gettingImage {
                    case .success(let image):
                        
                        DispatchQueue.main.async{
                            
                            cell.avatar.hideSkeleton()
                            cell.avatar.image = image
                        }
                        
                        
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    
                }
                .disposed(by: bag)

            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatVC") as! ChatVC
        
        chatVC.guest = conversations[indexPath.row].with!
        chatVC.addSentMessageToConversationsCallback = {[weak self] message in
            
            self?.insertRawMessageToConverstations(textMessage: message)
  
        }
        chatVC.updateReadStatusCallback = {[weak self] id in
            
            self?.updateReadStatus(id: id)
            
        }
        
        self.pushMessageToChildVC = {[weak chatVC]
            msg in
            
            chatVC?.insertMessage(msg)
            
        }
        
        self.navigationController?.pushViewController(chatVC, animated: true)

    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            toDeleteConversationIndexPath = indexPath
            let planetToDelete = conversations[indexPath.row]
            confirmDelete(conversation: planetToDelete)
        }
    }
    
    private func confirmDelete(conversation: Conversation) {
        
        let alert = UIAlertController(title: "Delete conversation", message: "Are you sure you want to permanently delete conversation with  \(conversation.with!)?", preferredStyle: .actionSheet)
        
        let delete = UIAlertAction(title: "Delete", style: .destructive, handler: handleDeleteOfConversation)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: cancelDeleteOfConversation)
        
        alert.addAction(delete)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    private func handleDeleteOfConversation(alertAction: UIAlertAction!) -> Void {
        
        if let indexPath = toDeleteConversationIndexPath {
            
            let _ = apiMainClient.request(APIMainRequests.deleteConversationWith(login: conversations[indexPath.row].with!))
                
                .subscribe {[weak self] (deleting)  in
                    switch deleting {
                    case .success( _):
                        
                        DispatchQueue.main.async {
                            
                            
                            self?.tableView.beginUpdates()
                            
                            self?.conversations.remove(at: indexPath.row)
                            
                            self?.tableView.deleteRows(at: [indexPath], with: .automatic)
                            
                            self?.toDeleteConversationIndexPath = nil
                            
                            self?.tableView.endUpdates()
                            
                        }
                        
                        
                    case .failure(let error):
                        
                        print(error.localizedDescription)
                    }
  
                }
                .disposed(by: bag)
 
        }
    }
    
    
    private func cancelDeleteOfConversation(alertAction: UIAlertAction!) {
        toDeleteConversationIndexPath = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if segue.identifier == "showSearchUserVC"{
            
            let searchUserVC = segue.destination as! SearchUserVC
            
            searchUserVC.addSentMessageToConversationsCallback = {[weak self] message in
                
                self?.insertRawMessageToConverstations(textMessage: message)
                
                
            }
            searchUserVC.updateReadStatusCallback = {[weak self] id in
                
                self?.updateReadStatus(id: id)
                
            }
  
        }
    }
    
    
}
