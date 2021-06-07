//
//  GuestVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import RxSwift
import SkeletonView
import FacebookLogin

class GuestVC: UICollectionViewController {
    
    var refresher: UIRefreshControl!
    var header: HeaderV?
    var headerLoaded = false
    
    var apiMainClient = APIMainClient()
    var apiCloudinaryClient = APICloudinaryClient()
    let bag = DisposeBag()
    var userFollowedUnfollowed = PublishSubject<Bool>()
    
    var currentUser: User?
    var guestUser: User?
    var posts = [Post]()
    var followers = [String]()
    var followees = [String]()
    var postsParameters = [String:Any]()
    
    var diffCalculator: CollectionViewDiffCalculator<String>?
    var postsImageIDs = [String](){
        
        didSet {
            self.diffCalculator?.rows = postsImageIDs
        }
    }
    
    
    var picturesToBeDisplayed: Int = 9
    var pageToDisplay: Int = 1
    var postDisplayedIndex: Int?
    
    
    deinit{
        print("GuestVC deinit")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.delegate = self
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = .systemBackground
        
        self.diffCalculator = CollectionViewDiffCalculator<String> (collectionView: self.collectionView!, initialRows: self.postsImageIDs)
        
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView?.addSubview(refresher)
        
        loadPosts()
        
    }
    
    @objc private func loadPosts() {

    _ = self.apiMainClient.request(APIMainRequests.getPosts(login: guestUser!.login!, page: pageToDisplay))
    
    .subscribe { [weak self] (gettingPosts)  in
        switch gettingPosts {
        case .success(let downloadedPosts):
            
            var imageIDs = [String]()
            var posts = [Post]()
            
            for post in downloadedPosts.posts_user! {
                
                
                posts.append(post)
                imageIDs.append(post.image_id!)
                
            }

            self?.posts += posts
            self?.postsImageIDs += imageIDs
            
        case .failure(let error):
            
            print(error.localizedDescription)
            
            
        }}
        
        
        .disposed(by: bag)
    
    }
    
    @objc private func refresh(){
        
        headerLoaded = false
        
        self.postsImageIDs.removeAll(keepingCapacity: false)
        self.posts.removeAll(keepingCapacity: false)
        
        pageToDisplay = 1
        loadPosts()
        loadHeader(header: self.header!)
        refresher.endRefreshing()

    }
    
    
    @objc private func loadHeader(header: HeaderV) {
        
        
        header.fullname.hideSkeleton()
        header.fullname.text = self.guestUser!.fullname!
        header.descriptionTxtV.hideSkeleton()
        header.descriptionTxtV.text = self.guestUser?.description
        
        
        _ = apiMainClient.request(APIMainRequests.countUserPosts(login: guestUser!.login!)).flatMap {  (posts) -> Single<UIImage> in
            
            let count = posts.posts_count
            DispatchQueue.main.async{
                
                header.noPosts.hideSkeleton()
                
                header.noPosts.text = "\(count ?? 0)"
                   
            }
            
            return self.apiMainClient.request(APIMainRequests.getFollows(login: self.guestUser!.login!)).flatMap {  (follows) in
                
                self.followers = follows.followers!
                self.followees = follows.followees!
                
                
                if !follows.followers!.isEmpty{
                    
                    if follows.followers!.contains(self.currentUser!.login!){
                        
                        
                        DispatchQueue.main.async{
                            
                            header.button.setTitle("following", for: .normal)
                            header.button.backgroundColor = .systemGray6
                            
                            
                        }
                    }else{
                        
                        DispatchQueue.main.async{
                            
                            
                            header.button.setTitle("follow", for: .normal)
                            header.button.backgroundColor = .systemBlue
                            
                        }
                        
                    }
                    
                }
                
                
                DispatchQueue.main.async{
                    header.noFollowees.hideSkeleton()
                    header.noFollowers.hideSkeleton()
                    
                    header.noFollowers.text = String(follows.followers!.count)
                    header.noFollowees.text = String(follows.followees!.count)
                    
                }
                
                if self.guestUser!.image_id != nil {
                    
                    let pictureSize = UIHelper.calculatePixelSizeToDownload(imageViewHeight: header.avatarDimensions!.height, imageViewWidth: header.avatarDimensions!.width, imageHeight: self.guestUser!.image_height!, imageWidth: self.guestUser!.image_width!)
                    
                    let url = self.apiCloudinaryClient.generateResizedImageUrl(height: pictureSize.height, width: pictureSize.width, publicID: self.guestUser!.image_id!)
                    
                    
                    return self.apiCloudinaryClient.downloadImage(call: CloudinaryCall(url: url))
                    
                    
                    
                }else{
                    
                    let image = UIImage(named: "avatar.png")
                    
                    return Single.just(image!)
                    
                }
                
            }
            
        }
        
        .subscribe {(gettingImage)  in
            
            switch gettingImage {
            case .success(let image):
                
                
                DispatchQueue.main.async{
                    
                    header.avatar.hideSkeleton()
                    header.avatar.image = image
                }
                
                
            case .failure(let error):
                print(error.localizedDescription)
            }
            
        }
        .disposed(by: bag)
        

    }
    
    @objc private func loadMorePosts(){
        
        pageToDisplay += 1
        loadPosts()
        
    }
    
    @objc private func updateHeader(){
        
        loadHeader(header: self.header!)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let postVC = self.storyboard?.instantiateViewController(withIdentifier: "PostVC") as! PostVC
        postVC.posts = posts
        postVC.postsImageIDs = postsImageIDs
        postVC.userOfPosts = guestUser
        postVC.currentUser = currentUser
        postVC.scrollTo = indexPath
        self.navigationController?.pushViewController(postVC, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        
        if indexPath.item == postsImageIDs.count - 1{
            
            self.loadMorePosts()
            
        }
        
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return postsImageIDs.count
    }
   

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath) as! HeaderV
        
        if !headerLoaded {
            header.avatar.isSkeletonable = true
            header.fullname.isSkeletonable = true
            header.descriptionTxtV.isSkeletonable = true
            header.noPosts.isSkeletonable = true
            header.noFollowers.isSkeletonable = true
            header.noFollowees.isSkeletonable = true
            
            header.avatar.showAnimatedSkeleton(usingColor: .systemGray6, animation: nil, transition: SkeletonTransitionStyle.none)
            header.fullname.showAnimatedSkeleton(usingColor: .systemGray6, animation: nil, transition: SkeletonTransitionStyle.none)
            header.descriptionTxtV.showAnimatedSkeleton(usingColor: .systemGray6, animation: nil, transition: SkeletonTransitionStyle.none)
            header.noPosts.showAnimatedSkeleton(usingColor: .systemGray6, animation: nil, transition: SkeletonTransitionStyle.none)
            header.noFollowers.showAnimatedSkeleton(usingColor: .systemGray6, animation: nil, transition: SkeletonTransitionStyle.none)
            header.noFollowees.showAnimatedSkeleton(usingColor: .systemGray6, animation: nil, transition: SkeletonTransitionStyle.none)
            
            
            loadHeader(header: header)
            
            header.userFollowedUnfollowed.subscribe { [weak self] (event) in
                guard let `self` = self, let header = self.header, event.element == true else { return }
                self.loadHeader(header: header)
            }.disposed(by: bag)
            
            
            
            
            header.followCallback = { [weak self, weak header] in
                
                var parameters = [String:Any]()
                parameters["followee_login"] = self?.guestUser!.login
                
                _ = self?.apiMainClient.request(APIMainRequests.follow(parameters: parameters))
                    
                    .subscribe {(following)  in
                        
                        switch following {
                        case .success(let message):
                            
                            header?.userFollowedUnfollowed.onNext(true)
                            
                            if message.message == APIResponseMessageText.followed.rawValue{
                                
                                DispatchQueue.main.async{
                                    
                                    header?.button.setTitle("following", for: .normal)
                                    header?.button.backgroundColor = .systemGray6
                                    
                                }
                                
                            }else if message.message == APIResponseMessageText.unfollowed.rawValue{
                                
                                
                                DispatchQueue.main.async{
                                    
                                    
                                    header?.button.setTitle("follow", for: .normal)
                                    header?.button.backgroundColor = .systemBlue
                                    
                                }
                                
                                
                            }
                            
                            
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                        
                    }
                    .disposed(by: header!.bag)
                
                
            }
            
            let postsTap = UITapGestureRecognizer(target: self, action: #selector(self.postsTap))
            postsTap.numberOfTapsRequired = 1
            header.noPosts.isUserInteractionEnabled = true
            header.noPosts.addGestureRecognizer(postsTap)
            
            let followersTap = UITapGestureRecognizer(target: self, action: #selector(self.followersTap))
            followersTap.numberOfTapsRequired = 1
            header.noFollowers.isUserInteractionEnabled = true
            header.noFollowers.addGestureRecognizer(followersTap)
            
            let followingsTap = UITapGestureRecognizer(target: self, action: #selector(self.followingsTap))
            followingsTap.numberOfTapsRequired = 1
            header.noFollowees.isUserInteractionEnabled = true
            header.noFollowees.addGestureRecognizer(followingsTap)
            
            self.header = header
            headerLoaded = true
            return self.header!
            
        }else{
            
            return self.header!
        }
    }
    
    @objc func postsTap(recognizer: UITapGestureRecognizer) {
        
        if !postsImageIDs.isEmpty{

            let index = IndexPath(item: 0, section: 0)
            self.collectionView?.scrollToItem(at: index, at: .top, animated: true)
        }

        
        
    }
    
    @objc func followersTap(recognizer: UITapGestureRecognizer) {
        
        if followers.count != 0{
            let followersVC = self.storyboard?.instantiateViewController(withIdentifier: "followsVC") as! FollowsVC
            
            followersVC.type = .followers
            followersVC.follows = followers
            followersVC.user = guestUser
            
            followersVC.userFollowedUnfollowed.subscribe { [weak self] (event) in
                guard let `self` = self, let header = self.header, event.element == true else { return }
                self.loadHeader(header: header)
            }.disposed(by: bag)
            
            
            self.navigationController?.pushViewController(followersVC, animated: true)
        }
        
    }
    
    @objc func followingsTap(recognizer: UITapGestureRecognizer) {
        
        if followers.count != 0{
            let followeesVC = self.storyboard?.instantiateViewController(withIdentifier: "followsVC") as! FollowsVC
            
            followeesVC.type = .followees
            followeesVC.follows = followees
            followeesVC.user = guestUser
            
            followeesVC.userFollowedUnfollowed.subscribe { [weak self] (event) in
                guard let `self` = self, let header = self.header, event.element == true else { return }
                self.loadHeader(header: header)
            }.disposed(by: bag)
            
            self.navigationController?.pushViewController(followeesVC, animated: true)
        }
        
        
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Cell
        
        cell.picture.isSkeletonable = true
        
        cell.picture.showAnimatedSkeleton(usingColor: .systemGray6, animation: nil, transition: SkeletonTransitionStyle.none)
        
        
        cell.tag = indexPath.item
        
        if !postsImageIDs.isEmpty && cell.tag == indexPath.item{
            
            let pictureSize = UIHelper.calculatePixelSizeToDownload(imageViewHeight: cell.pictureDimensions!.height, imageViewWidth: cell.pictureDimensions!.width, imageHeight: posts[indexPath.item].image_height!, imageWidth: posts[indexPath.item].image_width!)
            let url = self.apiCloudinaryClient.generateResizedImageUrl(height: pictureSize.height, width: pictureSize.width, publicID: postsImageIDs[indexPath.item])
            
            let _ = self.apiCloudinaryClient.downloadImage(call: CloudinaryCall(url:url))
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
        
        return cell
    }
        
    
}

extension GuestVC: SkeletonCollectionViewDataSource{
    func numSections(in collectionSkeletonView: UICollectionView) -> Int{
        
        return 1
    }
    func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        
        return postsImageIDs.count
    }
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier{
        
        return "Cell"
    }
    
    
    
    
    
    
    
}
