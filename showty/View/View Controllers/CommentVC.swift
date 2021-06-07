//
//  CommentVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import RxSwift
import SkeletonView
import InputBarAccessoryView




class CommentVC: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputBar: InputBarAccessoryView!
    @objc var refresher = UIRefreshControl()
    
    var apiMainClient = APIMainClient()
    var apiCloudinaryClient = APICloudinaryClient()
    let bag = DisposeBag()
    
    var currentuser: User?
    var post: Post?
    
     var diffCalculator: TableViewDiffCalculator<String>?
       var commentsTexts = [String](){
           
           didSet {
               self.diffCalculator?.rows = commentsTexts
           }
       }
    var comments = [Comment]()
    

    @objc func handleKeyboardShow(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        tableView.contentInset.top = keyboardValue.height - (navigationController?.navigationBar.bounds.height)! + 8.0
        tableView.verticalScrollIndicatorInsets.top = keyboardValue.height + 8.0
    }
    
    @objc func handleKeyboardHide(notification: Notification) {

        tableView.contentInset.top = 0 + 8.0
        tableView.verticalScrollIndicatorInsets.top = 0 + 8.0
    }
    
    
   
    override func viewDidLoad() {
        
        super.viewDidLoad()
   
        
        self.becomeFirstResponder()
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShow),name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardHide),name: UIResponder.keyboardWillHideNotification, object: nil)
      

        tableView.delegate = self
        tableView.dataSource = self
        
        inputBar.delegate = self
        inputBar.inputTextView.setup()
        inputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
       
      
        configureLeftInputBarItem()
        
        self.diffCalculator = TableViewDiffCalculator<String> (tableView: self.tableView!, initialRows: self.commentsTexts)
       
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 600
        tableView.keyboardDismissMode = .interactive
        
    
        loadComments()
    

    }
    
    
    
    private func loadLatestComment(){
        
        _ = self.apiMainClient.request(APIMainRequests.getLatestComment(post_id: self.post!.post_id!))
               
               .subscribe { [unowned self] (gettingLatestComment)  in
               switch gettingLatestComment {
               case .success(let downloadedComment):
                   
          
                self.comments.append(downloadedComment)
                self.commentsTexts.append(downloadedComment.comment!)
                   
                  
                   
               case .failure(let error):
                   
                   print(error.localizedDescription)
                   
                   
               }
                
                    }

               .disposed(by: bag)
  
    }
    
    
    private func loadComments(){
        
        commentsTexts.removeAll()
        comments.removeAll()
        
        _ = self.apiMainClient.request(APIMainRequests.getComments(post_id: self.post!.post_id!))
        
        .subscribe { [unowned self] (gettingComments)  in
        switch gettingComments {
        case .success(let downloadedComments):
            
            var commentsTexts = [String]()
            var comments = [Comment]()
            
            for comment in downloadedComments.comments! {
                
                
                comments.append(comment)
                commentsTexts.append(comment.comment!)
                
            }
   
            self.comments += comments
            self.commentsTexts += commentsTexts
            
           
            
        case .failure(let error):
            
            print(error.localizedDescription)
            
            
        }}
        
        
        .disposed(by: bag)
        
    }
    
    
    private func configureLeftInputBarItem() {
        
         inputBar.setLeftStackViewWidthConstant(to: 46, animated: false)
        
        let leftButton = InputBarButtonItem()
            .configure {

                $0.contentHorizontalAlignment = .center
                $0.contentVerticalAlignment = .center
                $0.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .regular)
                $0.setSize(CGSize(width: 46, height: 36), animated: false)
            
                
            }.onTextViewDidChange { [weak self](item, textView) in
                
                
                if textView.text.count > 0{
                    
                    
                item.title = "\(textView.text.count)/500"
                item.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .regular)
                
                   let isOverLimit = textView.text.count > 500
                  
                   if isOverLimit {
                    self?.inputBar.inputTextView.text = String(String(textView.text).dropLast())
                     
                   }
              
                    item.onTouchUpInside{_ in }
                    
                }else{
                    
                    item.title = ""
                    item.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .regular)
                 
                    
                }
            
                
        }
 
        let leftItems = [ leftButton]
        

        configureInputBarPadding()
       
        inputBar.setStackViewItems(leftItems, forStack: .left, animated: false)
       
        
    }
    
    private func configureInputBarPadding() {

        inputBar.middleContentViewPadding.right = 8
        inputBar.middleContentViewPadding.left = 8

    }
    
   
    override func viewWillAppear(_ animated: Bool) {
        
        self.tabBarController?.tabBar.isHidden = true
        

    
    }
    
    override func viewWillDisappear(_ animated: Bool) { 
        
        self.tabBarController?.tabBar.isHidden = false
       
    }
    
    internal func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    internal func numberOfSections(in tableView: UITableView) -> Int {
      
        return 1
    }
    
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
          return commentsTexts.count
          
      }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
         let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
        
        
        cell.tag = indexPath.row
               
        if !comments.isEmpty && cell.tag == indexPath.item{
            
            if !commentsTexts.isEmpty && cell.tag == indexPath.item{
            
                cell.comment.numberOfLines = 0
                cell.comment.enabledTypes = [.hashtag]
                cell.comment.handleHashtagTap { [weak self] hashtag in
                    
                    let hashtagVC = self?.storyboard?.instantiateViewController(withIdentifier: "HashtagVC") as! HashtagVC
                    hashtagVC.hashtag = hashtag
                    hashtagVC.currentuser = self?.currentuser
                    self?.navigationController?.pushViewController(hashtagVC, animated: true)
                    
                }
                cell.comment.text = self.commentsTexts[indexPath.item]
                cell.login.text = self.comments[indexPath.item].login
                
                if let timeDiff = UIHelper.calculateTimeDiff(dateInString: comments[indexPath.item].comment_date!){
                    cell.time.text = timeDiff
                }else{
                    cell.time.text = ""
                    
                }
                
            _ = apiMainClient.request(APIMainRequests.getUser(login: comments[indexPath.item].login!)).flatMap { (user) -> Single<UIImage> in
            
              
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
                                
                                cell.avatar.image = image
                                
                            }
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                    
                    }
            .disposed(by: bag)
                
            
            }}
        return cell
 
    }

}

extension CommentVC: InputBarAccessoryViewDelegate{
    

    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        var parameters = [String : Any]()
        
        parameters["post_id"] = post?.post_id
        parameters["comment"] = inputBar.inputTextView.text
        
        
       let _ = apiMainClient.request(APIMainRequests.comment(parameters: parameters))
        
                .subscribe {(commenting)  in
        
                            switch commenting {
                            case .success( _):
        
                              DispatchQueue.main.sync{
        
                                inputBar.inputTextView.text = ""
                                inputBar.reloadPlugins()
        
                                self.loadLatestComment()
        
                                }
        
        
                            case .failure(let error):
                                print(error.localizedDescription)
                            }
        
                        }
                .disposed(by: bag)
        
    }
    
}
