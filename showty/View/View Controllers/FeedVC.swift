//
//  PostVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import SkeletonView
import RxSwift



class FeedVC: UITableViewController {
    
    var refresher: UIRefreshControl!
    
    
    let apiMainClient = APIMainClient()
    let apiCloudinaryClient = APICloudinaryClient()
    var bag = DisposeBag()
    
    var diffCalculator: TableViewDiffCalculator<String>?
    var postIndexDeleted = PublishSubject<Int>()
    

    var currentUser: User?
    var timeArray = [Date?]()
    
    var posts = [Post]()
    var postsImageIDs = [String](){
        
        didSet {self.diffCalculator?.rows = postsImageIDs}
    }
    
    var pageToDisplay = 1
    let perPage = 3
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        self.diffCalculator = TableViewDiffCalculator<String>(tableView: self.tableView!, initialRows: self.postsImageIDs)
        
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 500
        
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView?.addSubview(refresher)
        
        loadPosts()
        
    }
    
    private func loadPosts(){
        
        _ = self.apiMainClient.request(APIMainRequests.loggedUser()).flatMap { (user) -> Single<FeedPosts> in
            
            self.currentUser = user
            
            return self.apiMainClient.request(APIMainRequests.getPostsOfFeed(page: self.pageToDisplay, per_page: self.perPage)) }
            
            .subscribe { [unowned self] (gettingPosts)  in
                switch gettingPosts {
                case .success(let downloadedPosts):
                    
                    var imageIDs = [String]()
                    var posts = [Post]()
                    
                    for post in downloadedPosts.posts_of_feed! {
                        
                        
                        posts.append(post)
                        imageIDs.append(post.image_id!)
                        
                    }
                    
                    
                    self.posts += posts
                    self.postsImageIDs += imageIDs
                    
                case .failure(let error):
                    
                    print(error.localizedDescription)
                    
                    
                }}
            
            
            .disposed(by: bag)
        
    }
    
    @objc private func refresh(){
        
        
        self.postsImageIDs.removeAll(keepingCapacity: false)
        self.posts.removeAll(keepingCapacity: false)
        
        pageToDisplay = 1
        loadPosts()
        refresher.endRefreshing()
        
        
        
    }
    
    @objc func loadMorePosts(){
        
        pageToDisplay += 1
        loadPosts()
        
    }
    
    
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return postsImageIDs.count
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if indexPath.item == postsImageIDs.count - 1{ self.loadMorePosts() }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        
        
        cell.picture.isSkeletonable = true
        cell.avatar.isSkeletonable = true
        cell.picture.showAnimatedSkeleton(usingColor: .systemGray6, animation: nil, transition: SkeletonTransitionStyle.none)
        cell.avatar.showAnimatedSkeleton(usingColor: .systemGray6, animation: nil, transition: SkeletonTransitionStyle.none)
        
        cell.tag = indexPath.item
        
        if !postsImageIDs.isEmpty && cell.tag == indexPath.item{
            
            cell.loginBtn.setTitle(posts[indexPath.item].login!, for: .normal)
            cell.loginBtn.sizeToFit()
            
            cell.descriptionTxt.numberOfLines = 0
            cell.descriptionTxt.enabledTypes = [.hashtag]
            
            cell.descriptionTxt.handleHashtagTap { [weak self] (hashtag) in
                
                let hashtagVC = self?.storyboard?.instantiateViewController(withIdentifier: "HashtagVC") as! HashtagVC
                hashtagVC.hashtag = hashtag
                
                _ = self?.apiMainClient.request(APIMainRequests.loggedUser())
                    
                    .subscribe {(gettingUser)  in
                        
                        switch gettingUser {
                        case .success(let user):
                            
                            hashtagVC.currentuser = user
                            
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                        
                    }
                    .disposed(by: self!.bag)
                
                
                
                
                self?.navigationController?.pushViewController(hashtagVC, animated: true)
                
            }
            
            cell.descriptionTxt.text = posts[indexPath.item].description
            
            cell.descriptionTxt.sizeToFit()
            
            if let timeDiff = UIHelper.calculateTimeDiff(dateInString: posts[indexPath.item].date!){
                cell.time.text = timeDiff
            }else{
                cell.time.text = ""
                
            }
            
            
        }
        
        
        _ = apiMainClient.request(APIMainRequests.getUser(login: posts[indexPath.item].login!)).flatMap { (user) -> Single<UIImage> in
            
            
            cell.userCallback = { [weak self] in
                
                if self!.currentUser != user {
                    
                    DispatchQueue.main.async{
                        
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        
                        let guestVC = storyboard.instantiateViewController(withIdentifier: "GuestVC") as! GuestVC
                        
                        guestVC.currentUser = self!.currentUser
                        guestVC.guestUser = user
                        
                        self?.navigationController?.pushViewController(guestVC, animated: true)
                        
                    }
                }
            }
            
            
            if user.image_id != nil {
                
                let pictureSize = UIHelper.calculatePixelSizeToDownload(imageViewHeight: cell.avatarDimensions!.height, imageViewWidth: cell.avatarDimensions!.width ,imageHeight: user.image_height!, imageWidth: user.image_width!)
                
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
        
        
        if !postsImageIDs.isEmpty && cell.tag == indexPath.item{
            
            let pictureSize = UIHelper.calculatePixelSizeToDownload(imageViewHeight: cell.pictureDimensions!.height, imageViewWidth: cell.pictureDimensions!.width, imageHeight: posts[indexPath.item].image_height!, imageWidth: posts[indexPath.item].image_width!)
            let url = self.apiCloudinaryClient.generateResizedImageUrl(height: pictureSize.height, width: pictureSize.width, publicID: posts[indexPath.item].image_id!)
            
            _ = self.apiCloudinaryClient.downloadImage(call: CloudinaryCall(url: url))
                .subscribe {(gettingImage)  in
                    
                    switch gettingImage {
                    case .success(let image):
                        
                        
                        DispatchQueue.main.async{
                            
                            cell.picture.image = image
                            cell.picture.hideSkeleton()
                            
                        }
                        
                    case .failure(let error):
                        print(error.localizedDescription)
                        
                        
                    }
                    
                }
                .disposed(by: bag)
        }
        
        
        cell.commentCallback = {[weak self] in
            
            let commentVC = self?.storyboard?.instantiateViewController(withIdentifier: "CommentVC") as! CommentVC
            commentVC.post = self?.posts[indexPath.item]
            
            _ = self?.apiMainClient.request(APIMainRequests.loggedUser())
                
                .subscribe {(gettingUser)  in
                    
                    switch gettingUser {
                    case .success(let user):
                        
                        commentVC.currentuser = user
                        
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    
                }
                .disposed(by: self!.bag)
            
            
            self?.navigationController?.pushViewController(commentVC, animated: true)
            
            
        }
        
        _ = cell.likeBtn.title(for: UIControl.State())
        
        
        let _ = self.apiMainClient.request(APIMainRequests.checkLike(post_id: self.posts[indexPath.item].post_id!)).flatMap {[weak self](message) -> Single<Post> in
            if message.message == APIResponseMessageText.liked.rawValue {
                
                DispatchQueue.main.async{
                    cell.likeBtn.setBackgroundImage(UIImage(named: "like.png"), for: .normal)
                }
                return self!.apiMainClient.request(APIMainRequests.countPostsLikes(post_id: (self!.posts[indexPath.item].post_id!)))
                
            }else if message.message == APIResponseMessageText.unliked.rawValue{
                
                DispatchQueue.main.async{
                    cell.likeBtn.setBackgroundImage(UIImage(named: "unlike.png"), for: .normal)
                }
                return self!.apiMainClient.request(APIMainRequests.countPostsLikes(post_id: (self!.posts[indexPath.item].post_id!)))
            }else{
                return (self!.apiMainClient.request(APIMainRequests.countPostsLikes(post_id: (self!.posts[indexPath.item].post_id!))))
                
            }
        }
        .subscribe {(countingLikes)  in
            
            
            switch countingLikes {
            case .success(let post):
                
                self.posts[indexPath.item].likes_count = post.likes_count
                DispatchQueue.main.async{
                    
                    if post.likes_count == 0{
                        
                        cell.noLikes.text = ""
                        
                    }else{
                        
                        cell.noLikes.text = String(self.posts[indexPath.item].likes_count!)
                        
                    }
                }
                
                
            case .failure(let error):
                print(error.localizedDescription)
                
            }
        }
        
        
        .disposed(by: bag)
        
        
        cell.likeUnlikeCallback = {[weak self] in
            
            
            var parameters = [String:Any]()
            parameters["post_id"] = self?.posts[indexPath.item].post_id
            
            let _ = self?.apiMainClient.request(APIMainRequests.like(parameters: parameters)).flatMap {(message) -> Single<Post> in
                if message.message == APIResponseMessageText.liked.rawValue {
                    
                    DispatchQueue.main.async{
                        cell.likeBtn.setBackgroundImage(UIImage(named: "like.png"), for: UIControl.State())
                    }
                    return (self?.apiMainClient.request(APIMainRequests.countPostsLikes(post_id: (self?.posts[indexPath.item].post_id!)!)))!
                    
                }else if message.message == APIResponseMessageText.unliked.rawValue{
                    
                    DispatchQueue.main.async{
                        cell.likeBtn.setBackgroundImage(UIImage(named: "unlike.png"), for: UIControl.State())
                    }
                    return (self?.apiMainClient.request(APIMainRequests.countPostsLikes(post_id: (self?.posts[indexPath.item].post_id!)!)))!
                }else{
                    return (self?.apiMainClient.request(APIMainRequests.countPostsLikes(post_id: (self?.posts[indexPath.item].post_id!)!)))!
                }
                
            }
            .subscribe {(countingLikes)  in
                
                
                switch countingLikes {
                case .success(let post):
                    
                    self?.posts[indexPath.item].likes_count = post.likes_count
                    DispatchQueue.main.async{
                        
                        if post.likes_count == 0{
                            
                            cell.noLikes.text = ""
                            
                        }else{
                            
                            cell.noLikes.text = String(self!.posts[indexPath.item].likes_count!)
                            
                        }
                    }
                    
                case .failure(let error):
                    print(error.localizedDescription)
                    
                }
                
            }
            .disposed(by: self!.bag)
            
        }
        
        cell.moreCallback = {[weak self] in
            
            if self!.currentUser?.login == self!.posts[indexPath.item].login{
                
                let alert = UIAlertController(title: "More", message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Delete Post", style: .destructive, handler: { _ in
                    
                    
                    _ = self!.apiMainClient.request(APIMainRequests.deletePost(post_id: self!.posts[indexPath.item].post_id!))
                        
                        .subscribe { [unowned self] (deletingPost)  in
                            
                            
                            switch deletingPost {
                            case .success(let message):
                                
                                DispatchQueue.main.async{
                                    UIHelper.displayAlert(viewController: self!, message: message.message!, title: nil, completion: { (action) in
                                                            if action.style == .cancel{
                                                                
                                                                self!.postIndexDeleted.onNext(indexPath.item)
                                                                
                                                                self!.postsImageIDs.remove(at: indexPath.item)
                                                                self!.posts.remove(at: indexPath.item)
                                                                
                                                                self?.navigationController?.popViewController(animated: true)
                                                                
                                                            }})
                                }
                                
                            case .failure(let error):
                                print(error.localizedDescription)
                            }}
                        
                        .disposed(by: self!.bag)
                }))
 
                alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
                
                self!.present(alert, animated: true, completion: nil)
                
            }
        }

        return cell
    }
    
}
