//
//  HashtagVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import RxSwift
import SkeletonView



class HashtagVC: UICollectionViewController {
    
    var refresher: UIRefreshControl!
    
    var header: HashtagV?
    var headerLoaded = false

    var apiMainClient = APIMainClient()
    var apiCloudinaryClient = APICloudinaryClient()
    let bag = DisposeBag()
    
    var currentuser: User?
    var hashtag: String?
    var posts = [Post]()
    var postsParameters = [String:Any]()
    
    var diffCalculator: CollectionViewDiffCalculator<String>?
    var postsImageIDs = [String](){
        
        didSet {
            self.diffCalculator?.rows = postsImageIDs
        }
    }

    var picturesToBeDisplayed: Int = 9
    var pageToDisplay: Int = 1
    
    
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
        
        var parameters = [String:Any]()
        parameters["hashtag"] = self.hashtag
        parameters["page"] = self.pageToDisplay
        
        
        let _ = self.apiMainClient.request(APIMainRequests.getPostsWithHashtag(parameters: parameters))
            .subscribe { [unowned self] (gettingPostsForHashtag)  in
                switch gettingPostsForHashtag {
                case .success(let downloadedPosts):
                    
                    var imageIDs = [String]()
                    var posts = [Post]()
                    
                    for post in downloadedPosts.posts_with_hashtag! {
                        
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
    
    private func loadHeader(header: HashtagV) {
        
        
        var parameters = [String:Any]()
        parameters["hashtag"] = self.hashtag
        
        
        let _ = self.apiMainClient.request(APIMainRequests.getLatestPostWithHashtag(parameters: parameters)).flatMap {(post) -> Single<UIImage> in
            
            
            
            if post.image_id != nil {
                
                let pictureSize = UIHelper.calculatePixelSizeToDownload(imageViewHeight: header.latestPictureDimensions!.height, imageViewWidth: header.latestPictureDimensions!.width,imageHeight: post.image_height!, imageWidth: post.image_width!)
                
                let url = self.apiCloudinaryClient.generateResizedImageUrl(height: pictureSize.height, width: pictureSize.width, publicID: post.image_id!)
                
                
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
                    
                    header.latestPicture.hideSkeleton()
                    header.latestPicture.image = image
                    
                }
                
            case .failure(let error):
                print(error.localizedDescription)
            }
            
        }
        .disposed(by: bag)
        
        
        let _ = self.apiMainClient.request(APIMainRequests.countHashtagSubscribers(hashtag: hashtag!))
            .subscribe {(gettingCounts)  in
                
                switch gettingCounts {
                case .success(let subscribers):
                    
                    DispatchQueue.main.async{
                        
                        header.subscribers.text = "\(String(describing: subscribers.subscribers_count!))" + " subscribers"
                    }
                    
                case .failure(let error):
                    print(error.localizedDescription)
                }
                
            }
            .disposed(by: bag)
        
        
        let _ = apiMainClient.request(APIMainRequests.checkSubscription(hashtag: hashtag!, subscriber: currentuser!.login!))
            
            .subscribe {(checkingSubscription)  in
                
                switch checkingSubscription {
                case .success(let message):
                    
                    if message.message == APIResponseMessageText.subscribed.rawValue{
                        
                        DispatchQueue.main.async{
                            
                            
                            header.subscribeButton.setTitle("following", for: .normal)
                            header.subscribeButton.backgroundColor = .systemGray6
                            
                            
                        }
                        
                    }else if message.message == APIResponseMessageText.unsubscribed.rawValue{
                        
                        DispatchQueue.main.async{
                            
                            
                            header.subscribeButton.setTitle("follow", for: .normal)
                            header.subscribeButton.backgroundColor = .systemBlue
                            
                        }
                    }

                case .failure(let error):
                    print(error.localizedDescription)
                }
                
            }
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
    
    @objc private func loadMorePosts(){
        
        pageToDisplay += 1
        loadPosts()
        
    }
    
    @objc private func updateHeader(){
        
        loadHeader(header: self.header!)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return postsImageIDs.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) { }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if indexPath.item == postsImageIDs.count - 1{ self.loadMorePosts() }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath) as! HashtagV
        
        header.hashtag.text = "#" + "\(String(describing: self.hashtag!))"
        
        if !headerLoaded {
            
            header.latestPicture.isSkeletonable = true
            
            header.latestPicture.showAnimatedSkeleton(usingColor: .systemGray6, animation: nil, transition: SkeletonTransitionStyle.none)
            
            loadHeader(header: header)
            
            header.subscribeCallback = { [weak self] in
                
                var parameters = [String:Any]()
                parameters["hashtag"] = self?.hashtag
                
                let _ = self?.apiMainClient.request(APIMainRequests.subscribe(parameters: parameters))
                    
                    .subscribe {(checkingSubscription)  in
                        
                        switch checkingSubscription {
                        case .success(let message):
                            
                            if message.message == APIResponseMessageText.subscribed.rawValue{
                                
                                DispatchQueue.main.async{
                                    
                                    header.subscribeButton.setTitle("following", for: .normal)
                                    header.subscribeButton.backgroundColor = .systemGray6
                                    
                                }
                                
                            }else if message.message == APIResponseMessageText.unsubscribed.rawValue{
                                
                                DispatchQueue.main.async{
                                    
                                    header.subscribeButton.setTitle("follow", for: .normal)
                                    header.subscribeButton.backgroundColor = .systemBlue
                                    
                                }
                            }
  
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                        
                    }
                    .disposed(by: self!.bag)

            }
            
            self.header = header
            headerLoaded = true
            return self.header!
        }else{
            
            return self.header!
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


extension HashtagVC: SkeletonCollectionViewDataSource{
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

