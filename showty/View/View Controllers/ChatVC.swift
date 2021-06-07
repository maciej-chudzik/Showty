//
//  ChatVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import RxSwift

class ChatVC: MessagesViewController{
    
    var messages = [MessageTypeExtended]()
    
    var addedEventHandlers = [UUID]()
    var guest = String()
    var addSentMessageToConversationsCallback: ((CustomMessage)->())?
    var updateReadStatusCallback: ((Int)->())?
    
    var attachmentManager = AttachmentManager()
    
    let apiMainClient = APIMainClient()
    let apiCloudinaryClient = APICloudinaryClient()
    let bag = DisposeBag()
    
    
    lazy var statusButton: StatusButton = {
        let button = StatusButton()
        button.setTitleColor(.label, for: .normal)
        button.setTitle(guest, for: .normal)
        return button
    }()
    
    
    deinit{
        
        print("ChatVC deinitialized")
        NotificationCenter.default.removeObserver(self)
        SocketIOMessenger.shared.removeHandlers(handlers: addedEventHandlers)
        
    }
    
    override func willMove(toParent parent: UIViewController?)
    {
        super.willMove(toParent: parent)
        
        if parent == nil{
            statusButton.removeFromSuperview()
        }
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ChatVC initialized")
        
        NotificationCenter.default.addObserver(self,selector:#selector(loadUnreadMessages), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardOnTap))
        
        messagesCollectionView.addGestureRecognizer(tap)
        
        extendedLayoutIncludesOpaqueBars = false
        scrollsToLastItemOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        
        configureStatusIndicator()
        
        configureChatLayout()
      
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        attachmentManager.delegate = self
        navigationController?.delegate = self
        
        messageInputBar.inputPlugins = [attachmentManager]
        attachmentManager.showAddAttachmentCell = false
        configureLeftInputBarItem()
        
        
        addedEventHandlers += addEventHandlers()
        
        SocketIOMessenger.shared.sendConnectedUsersUpdate()
        
        loadMessages()
        
        
    }
    
    private func configureChatLayout(){
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.setMessageIncomingAvatarSize(.zero)
            layout.setMessageOutgoingAvatarSize(.zero)
        
            
            
            layout.setMessageIncomingCellBottomLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: .zero))
            layout.setMessageOutgoingCellBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: .zero))
        }
        
    }
    
    private func configureStatusIndicator(){
        
        statusButton.translatesAutoresizingMaskIntoConstraints = false
        
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        navigationBar.addSubview(statusButton)
        
        NSLayoutConstraint.activate([
            
            statusButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor, constant: 0),
            statusButton.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor, constant: 0)
            
        ])
        
    }
    
    private func configureLeftInputBarItem() {
        
        messageInputBar.setLeftStackViewWidthConstant(to: 42, animated: false)
        
        let leftButton = InputBarButtonItem()
            .configure {
                $0.title = "+"
                $0.contentHorizontalAlignment = .center
                $0.contentVerticalAlignment = .center
                $0.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .regular)
                $0.setSize(CGSize(width: 42, height: 36), animated: false)
                $0.onTouchUpInside{  [weak self] _ in
                    
                    self?.messageInputBar.inputTextView.resignFirstResponder()
                    
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = .photoLibrary
                    self?.present(imagePicker, animated: true, completion: nil)
                    
                }
                
            }.onTextViewDidChange { [weak self](item, textView) in
                
                
                if textView.text.count > 0{
                    
                    
                    item.title = "\(textView.text.count)/640"
                    item.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .regular)
                    
                    let isOverLimit = textView.text.count > 640
                    
                    if isOverLimit {
                        self?.messageInputBar.inputTextView.text = String(String(textView.text).dropLast())
                        
                    }
                    
                    item.onTouchUpInside{_ in }
                    
                }else{
                    
                    item.title = "+"
                    item.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .regular)
                    item.onTouchUpInside{  [weak self] _ in
                        
                        self?.messageInputBar.inputTextView.resignFirstResponder()
                        
                        let imagePicker = UIImagePickerController()
                        imagePicker.delegate = self
                        imagePicker.sourceType = .photoLibrary
                        self?.present(imagePicker, animated: true, completion: nil)
                        
                    }
                }
                
            }
        
        let leftItems = [ leftButton]
        
        
        configureInputBarPadding()
        
        messageInputBar.setStackViewItems(leftItems, forStack: .left, animated: false)
        
        
    }
    
    private func configureInputBarPadding() {
        
        messageInputBar.middleContentViewPadding.right = 8
        messageInputBar.middleContentViewPadding.left = 8
        
    }
    
    @objc private func dismissKeyboardOnTap() {
        messageInputBar.inputTextView.resignFirstResponder()
        messagesCollectionView.scrollToLastItem()
    }
    
    
    
    private func addEventHandlers()->[UUID]{
        
        return [SocketIOMessenger.shared.getReadMessageID { [weak self] (id) in
            
            self?.updateReadStatus(id: id)
            
        },SocketIOMessenger.shared.getStartTypingEvent { [weak self] in
            
            self?.setTypingIndicatorViewHidden(false, animated: true, whilePerforming: nil) { (appeared) in
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
            
        },SocketIOMessenger.shared.getStoppedTypingEvent { [weak self] in
            
            
            self?.setTypingIndicatorViewHidden(true, animated: true, whilePerforming: nil) { (disappeared) in
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
            
        },SocketIOMessenger.shared.getConnectedUsers(completionHandler: { [weak self](connectedUsers) in
            
            self?.toogleStatusIndicator(connectedUsers: connectedUsers)
            
        })]
        
        
    }
    
    private func toogleStatusIndicator(connectedUsers: [String]){
        
        if connectedUsers.contains(guest){
            statusButton.isOnline = true
        }else{
            statusButton.isOnline = false
            
        }
        
        
    }
    
    private func updateReadStatus(id: Int){
        
        for i in self.messages.indices{
            
            if Int(self.messages[i].messageId) == id {
                
                self.messages[i].read = true
                
                self.messagesCollectionView.performBatchUpdates({
                    
                    self.messagesCollectionView.reloadSections([i])
                    if self.isLastSectionVisible() == true {
                        self.messagesCollectionView.scrollToLastItem(animated: true)
                    }
                    
                }, completion: nil)
            }
            
        }
        
    }
    
    private func loadMessages(){
        let _ = apiMainClient.request(APIMainRequests.loggedUser()).flatMap { user -> Single<CustomMessages> in
            
            return self.apiMainClient.request(APIMainRequests.getMessagesOfConversation(of: user.login!, with: self.guest))}
            .subscribe { (loadingMessages) in
                switch loadingMessages {
                case .success(let messages):
                    guard let messages = messages.messages else { return }
                    
                    for message in messages{
                        
                        self.messages.append(message.ToMessageTypeExtended())
                        
                    }
                    DispatchQueue.main.async {
                        self.messagesCollectionView.reloadData()
                        self.messagesCollectionView.scrollToLastItem(animated: false)
                        
                    }
                    
                case .failure(let error):
                    
                    print(error.localizedDescription)
                    
                }
                
            }
            .disposed(by: bag)
    }
    
    @objc private func loadUnreadMessages(){
        
        let _ = apiMainClient.request(APIMainRequests.loggedUser()).flatMap { user -> Single<CustomMessages> in
            
            return self.apiMainClient.request(APIMainRequests.getUnreadMessagesOfConversation(of: user.login!, with: self.guest))
            
        }
        
        .subscribe { (loadingunreadTextMessages) in
            switch loadingunreadTextMessages {
            case .success(let unreadTextMessages):
                guard let unreadTextMessages = unreadTextMessages.messages else { return }
                
                for unreadTextMessage in unreadTextMessages{
                    
                    self.insertMessage(unreadTextMessage.ToMessageTypeExtended())
                    
                    self.addSentMessageToConversationsCallback?(unreadTextMessage)
                    
                }
            case .failure(let error):
                
                print(error.localizedDescription)
                
            }
            
        }
        .disposed(by: bag)
        
    }
    
    func insertMessage(_ message: MessageTypeExtended) {
        messages.append(message)
        
        DispatchQueue.main.async {
            
            self.messagesCollectionView.performBatchUpdates({
                self.messagesCollectionView.insertSections([self.messages.count - 1])
                if self.messages.count >= 2 {
                    self.messagesCollectionView.reloadSections([self.messages.count - 2])
                }
            }, completion: { [weak self] _ in
                if self?.isLastSectionVisible() == true {
                    self?.messagesCollectionView.scrollToLastItem(animated: true)
                }
            })
            
        }
    }
    
    
    @objc private func sendStopTypingMessage(){
        SocketIOMessenger.shared.sendStopTypingMessage(receiver: guest)
        
    }
    
    @objc private func sendStartTypingMessage(){
        SocketIOMessenger.shared.sendStartTypingMessage(receiver: guest)
        
    }
    
    private func isLastSectionVisible() -> Bool {
        
        guard !messages.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    private func isMessageRead(message: MessageTypeExtended) -> Bool{
        
        if message.read{
            return true
        }else{
            
            return false
        }
        
    }
    
    private func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        return !isPreviousMessageSameSender(at: indexPath)
    }
    
    private func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section - 1].sender.senderId
    }
    
    private func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messages.count else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section + 1].sender.senderId
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let cell = cell as? TypingIndicatorCell{
            
            cell.typingBubble.startAnimating()
        }
        
        
        if cell is TextMessageCell || cell is MediaMessageCell{
            
            
            guard let messagesCollectionView = collectionView as? MessagesCollectionView else {
                return
            }
            
            guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
                return
            }
            
            let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as! MessageTypeExtended
            
            
            if !isFromCurrentSender(message: message) && !isMessageRead(message: message)
                && self.navigationController?.visibleViewController == self
            {
                
                SocketIOMessenger.shared.updateReadStatus(msgID: Int(message.messageId)!){response in
                    
                    guard response else {return}
                    
                    self.updateReadStatusCallback?(Int(message.messageId)!)
                }
                
            }
            
        }
        
    }
    
}


extension ChatVC: InputBarAccessoryViewDelegate{
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        if !attachmentManager.attachments.isEmpty{
            
           let attachment = attachmentManager.attachments.first
            
            switch attachment {
                
                case .image(let image):
                
                    let _ =   self.apiCloudinaryClient.uploadImage(call: APICloudinary.uploadImage(imageData: image.pngData()!))
                    
                        .subscribe {(downloadingImage)  in
                            
                                switch downloadingImage {
                                case .success(let response):
                                    
                                   
                                 inputBar.invalidatePlugins()
                                    
                                 SocketIOMessenger.shared.sendMessage(sender: UserDefaults.standard.value(forKey: "host") as! String, receiver: self.guest, text: nil, url: response.url, completionHandler: { [weak self] msgSaved in
                                       
                                             if msgSaved != nil{
                                                     
                                                 self?.insertMessage(msgSaved!.ToMessageTypeExtended())
                                                 
                                                 self?.addSentMessageToConversationsCallback?(msgSaved!)
                                                
                                                 inputBar.reloadPlugins()
                                             
                                             }else{
                                                 
                                                return
                                                 
                                             }
                                    })
                          
                                case .failure(let error):
                                    print(error.localizedDescription)
                                }
                            
                            }
                    .disposed(by: bag)

            default:
                break
            }
            
        }else{
            
            SocketIOMessenger.shared.sendMessage(sender: UserDefaults.standard.value(forKey: "host") as! String, receiver: self.guest, text: text, url: nil, completionHandler: { [weak self] msgSaved in
               
                     if msgSaved != nil{
                             
                         self?.insertMessage(msgSaved!.ToMessageTypeExtended())
                         
                         self?.addSentMessageToConversationsCallback?(msgSaved!)
                         
                        inputBar.inputTextView.text = ""
                        inputBar.reloadPlugins()
                     
                     }else{
                         
                        return
                         
                     }
            })
            
        }
        
    }
      
    

    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
    
        
        if text.count > 0{
        
            self.perform(#selector(sendStartTypingMessage), with: guest)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(sendStopTypingMessage), object: nil)
            self.perform(#selector(sendStopTypingMessage), with: nil, afterDelay: 0.5)
            
        }
    }
    
}

extension ChatVC: MessagesDataSource{
    
    func currentSender() -> SenderType {
        return Sender(senderId: UserDefaults.standard.value(forKey: "host") as! String, displayName: UserDefaults.standard.value(forKey: "host") as! String)
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        if isTimeLabelVisible(at: indexPath){
        
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
    
        return nil
    }
    
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
    
        return NSAttributedString(string: "Read", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        return nil
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        return nil
    }
    
}

extension ChatVC: MessagesLayoutDelegate{
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        if isTimeLabelVisible(at: indexPath){
            return 10
        }
        
        return 0
        
    }
    
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        if isFromCurrentSender(message: message){
            
             let lastSection = messagesCollectionView.numberOfSections - 1
             guard lastSection >= 0, numberOfItems(inSection: lastSection, in: messagesCollectionView) > 0 else { return 0 }
             let lastIndexPath =  IndexPath(item: numberOfItems(inSection: lastSection, in: messagesCollectionView) - 1, section: lastSection)
                 

            if isMessageRead(message: message as! MessageTypeExtended) && indexPath.section == lastIndexPath.section{
                return 10
            }else{
                return 0
            }

        }
            return 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        if !isFromCurrentSender(message: message){
                   
            if !isPreviousMessageSameSender(at: indexPath) && isNextMessageSameSender(at: indexPath){
                return 10
            }else if !isPreviousMessageSameSender(at: indexPath) && !isNextMessageSameSender(at: indexPath){
                return 10
            }
        }
        
        return 0
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
}

extension ChatVC: MessagesDisplayDelegate{
    
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if isFromCurrentSender(message: message){
            return UIColor.systemBlue
        }
        return UIColor.systemGray2
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
    
        return UIColor.white
       
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        
        if message is MessageTypeExtended{
            
            switch message.kind{
                
            case .photo(let photoItem):
            
                
             let _ =   self.apiCloudinaryClient.downloadImage(call: CloudinaryCall(url: photoItem.url!.absoluteString))
                
                .subscribe {(gettingImage)  in
                        
                            switch gettingImage {
                            case .success(let image):
                                
                                DispatchQueue.main.async{
                                    
                                  imageView.image = image
                                }
                      
                            case .failure(let error):
                                print(error.localizedDescription)
                            }
                        
                        }
                .disposed(by: bag)
                
        
            default:
                break
            }
            
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = true
    }
    
    
}

extension ChatVC: AttachmentManagerDelegate{
    
    func attachmentManager(_ manager: AttachmentManager, shouldBecomeVisible: Bool) {
        
        setAttachmentManager(active: shouldBecomeVisible)
        
    }
    
    func attachmentManager(_ manager: AttachmentManager, didReloadTo attachments: [AttachmentManager.Attachment]) {
        messageInputBar.sendButton.isEnabled = manager.attachments.count > 0
    }
    
    func attachmentManager(_ manager: AttachmentManager, didInsert attachment: AttachmentManager.Attachment, at index: Int) {
        messageInputBar.sendButton.isEnabled = manager.attachments.count > 0
    }
    
    func attachmentManager(_ manager: AttachmentManager, didRemove attachment: AttachmentManager.Attachment, at index: Int) {
        messageInputBar.sendButton.isEnabled = manager.attachments.count > 0
    }
   


    func setAttachmentManager(active: Bool) {
        

        if active{
            
            messageInputBar.setMiddleContentView(attachmentManager.attachmentView, animated: true)
            messageInputBar.middleContentView?.backgroundColor = .systemBackground
            messageInputBar.rightStackView.alignment = .bottom
            messageInputBar.leftStackView.isHidden = true
          

        } else{

            messageInputBar.setMiddleContentView(messageInputBar.inputTextView, animated: true)
            messageInputBar.leftStackView.isHidden = false

        }
    }

    
}

extension ChatVC: UINavigationControllerDelegate{
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController.isKind(of:SearchUserVC.self) {
            navigationController.popToRootViewController(animated: false)
        }
    }
    
    
}

    
extension ChatVC: UIImagePickerControllerDelegate{
    
 func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
       
            if let pickedImage = info[.originalImage] as? UIImage {
                let handled = self.attachmentManager.handleInput(of: pickedImage)
                
                if !handled {
                    // throw error
                }
            }
        dismiss(animated: true)
    }
}
    


