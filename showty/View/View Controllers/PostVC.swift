//
//  PostVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import SkeletonView
import RxSwift
import Cloudinary


class PostVC: UITableViewController {
    
    deinit{
        
        print("PostVC deinit")
    }
   
    
    let client = APIMainClient()
    let apiCloudinaryClient = APICloudinaryClient()
    var bag = DisposeBag()
    
    var diffCalculator: TableViewDiffCalculator<String>?
    var postIndexDeleted = PublishSubject<Int>()
    
    var timeArray = [Date?]()
    var userOfPosts: User?
    var currentUser: User?
    
    
    var posts = [Post]()
        
    var postsImageIDs = [String](){

        didSet {self.diffCalculator?.rows = postsImageIDs}
    }
    
    var scrollTo: IndexPath?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView?.reloadData()
        tableView?.scrollToRow(at: scrollTo!, at: .middle, animated: false)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 500
        
        self.diffCalculator = TableViewDiffCalculator<String>(tableView: self.tableView!, initialRows: self.postsImageIDs)
    
    }
    

    override func numberOfSections(in tableView: UITableView) -> Int {
      
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     
        return postsImageIDs.count
        
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        
        cell.picture.image = nil
        cell.avatar.image = nil
        
        
       cell.tag = indexPath.item
        
        if !postsImageIDs.isEmpty && cell.tag == indexPath.item{
            
            
            
            cell.descriptionTxt.numberOfLines = 0
            cell.descriptionTxt.enabledTypes = [.hashtag]
            
            cell.descriptionTxt.handleHashtagTap { [weak self] (hashtag) in
                
                let hashtagVC = self?.storyboard?.instantiateViewController(withIdentifier: "HashtagVC") as! HashtagVC
                hashtagVC.hashtag = hashtag
                hashtagVC.currentuser = self?.userOfPosts
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
        
        if let user = userOfPosts {
            
            let pictureSize = UIHelper.calculatePixelSizeToDownload(imageViewHeight: cell.avatarDimensions!.height, imageViewWidth: cell.avatarDimensions!.width, imageHeight: user.image_height!, imageWidth: user.image_width!)
            let url = self.apiCloudinaryClient.generateResizedImageUrl(height: pictureSize.height, width: pictureSize.width, publicID: user.image_id!)
            
            cell.avatar.cldSetImage(url, cloudinary: self.apiCloudinaryClient.cloudinary)
            
        }
        

        if !postsImageIDs.isEmpty && cell.tag == indexPath.item{
            
            let pictureSize = UIHelper.calculatePixelSizeToDownload(imageViewHeight: cell.pictureDimensions!.height, imageViewWidth: cell.pictureDimensions!.width, imageHeight: posts[indexPath.item].image_height!, imageWidth: posts[indexPath.item].image_width!)
            let url = self.apiCloudinaryClient.generateResizedImageUrl(height: pictureSize.height/3, width: pictureSize.width/3, publicID: posts[indexPath.item].image_id!)
            
            cell.picture.cldSetImage(url, cloudinary: self.apiCloudinaryClient.cloudinary)
 
            
        }
        
        _ = cell.likeBtn.title(for: UIControl.State())
               
 
        let _ = self.client.request(APIMainRequests.checkLike(post_id: self.posts[indexPath.item].post_id!)).flatMap {[weak self](message) -> Single<Post> in
            if message.message == APIResponseMessageText.liked.rawValue {
                
                DispatchQueue.main.async{
                    cell.likeBtn.setBackgroundImage(UIImage(named: "like.png"), for: .normal)
                }
                return self!.client.request(APIMainRequests.countPostsLikes(post_id: (self!.posts[indexPath.item].post_id!)))
                   
            }else if message.message == APIResponseMessageText.unliked.rawValue{
                      
                DispatchQueue.main.async{
                    cell.likeBtn.setBackgroundImage(UIImage(named: "unlike.png"), for: .normal)
                }
                return self!.client.request(APIMainRequests.countPostsLikes(post_id: (self!.posts[indexPath.item].post_id!)))
            }else{
                return (self!.client.request(APIMainRequests.countPostsLikes(post_id: (self!.posts[indexPath.item].post_id!))))
                
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

        
        
        cell.commentCallback = {[weak self] in
            
            let commentVC = self?.storyboard?.instantiateViewController(withIdentifier: "CommentVC") as! CommentVC
            commentVC.post = self?.posts[indexPath.item]
            commentVC.currentuser = self?.userOfPosts
            self?.navigationController?.pushViewController(commentVC, animated: true)
            
        }
        

        cell.likeUnlikeCallback = {[weak self] in


            var parameters = [String:Any]()
            parameters["post_id"] = self?.posts[indexPath.item].post_id!

            let _ = self?.client.request(APIMainRequests.like(parameters: parameters)).flatMap {[weak self](message) -> Single<Post> in
                if message.message == APIResponseMessageText.liked.rawValue {
                             DispatchQueue.main.async{
                                cell.likeBtn.setBackgroundImage(UIImage(named: "like.png"), for: UIControl.State())
                           }
                    return (self?.client.request(APIMainRequests.countPostsLikes(post_id: (self?.posts[indexPath.item].post_id!)!)))!

                }else if message.message == APIResponseMessageText.unliked.rawValue{

                            DispatchQueue.main.async{
                                cell.likeBtn.setBackgroundImage(UIImage(named: "unlike.png"), for: UIControl.State())
                           }
                    return (self?.client.request(APIMainRequests.countPostsLikes(post_id: (self?.posts[indexPath.item].post_id!)!)))!
                }else{
                    return (self?.client.request(APIMainRequests.countPostsLikes(post_id: (self?.posts[indexPath.item].post_id!)!)))!

                }

            }

            .subscribe {(countingLikes)  in


                           switch countingLikes {
                           case .success(let post):

                               self?.posts[indexPath.item].likes_count = post.likes_count
                                DispatchQueue.main.async{

                                    guard let self = self else {return}

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
            .disposed(by: self!.bag)

   }
        
        cell.moreCallback = {[weak self] in


            let alert = UIAlertController(title: "More", message: nil, preferredStyle: .actionSheet)


            if self!.userOfPosts == self!.currentUser{



            alert.addAction(UIAlertAction(title: "Delete Post", style: .destructive, handler: { [weak self]_ in



                _ = self!.client.request(APIMainRequests.deletePost(post_id: self!.posts[indexPath.item].post_id!))

                .subscribe { [weak self] (deletingPost)  in


                    switch deletingPost {
                    case .success(let message):

                         DispatchQueue.main.async{
                            UIHelper.displayAlert(viewController: self!, message: message.message!, title: nil, completion: { [weak self](action) in
                            if action.style == .cancel{

                                self?.postIndexDeleted.onNext(indexPath.item)

                                self?.postsImageIDs.remove(at: indexPath.item)
                                self?.posts.remove(at: indexPath.item)

                                self?.navigationController?.popViewController(animated: true)

                            }})
                        }

                    case .failure(let error):
                        print(error.localizedDescription)
                    }}

                    .disposed(by: self!.bag)
            }))

            }else{


                alert.addAction(UIAlertAction(title: "Follow", style: .destructive, handler: { _ in }))

        }


            alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

            self!.present(alert, animated: true, completion: nil)

        }

    
        return cell
    }


}

