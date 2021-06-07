//
//  FollowsVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import RxSwift
import SkeletonView



class FollowsVC: UITableViewController {
    

    var apicMainClient = APIMainClient()
    var apiCloudinaryClient = APICloudinaryClient()
    let bag = DisposeBag()
    var diffCalculator: TableViewDiffCalculator<String>?
    var follows = [String](){
    
    didSet {
        self.diffCalculator?.rows = follows
        }
    }
    
    var type: FollowsType?
    var user: User?
    var userFollowedUnfollowed = PublishSubject<Bool>()
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.diffCalculator = TableViewDiffCalculator<String> (tableView: self.tableView!, initialRows: self.follows)

        }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return follows.count
    }

    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "followsCell", for: indexPath) as! FollowsCell
        
        cell.avatar.isSkeletonable = true
        cell.login.isSkeletonable = true
        cell.followBtn.isSkeletonable = true
         
        cell.avatar.showAnimatedSkeleton(usingColor: .systemGray6, animation: nil, transition: SkeletonTransitionStyle.none)
        cell.login.showAnimatedSkeleton(usingColor: .systemGray6, animation: nil, transition: SkeletonTransitionStyle.none)
        cell.followBtn.showAnimatedSkeleton(usingColor: .systemGray6, animation: nil, transition: SkeletonTransitionStyle.none)
        
        cell.tag = indexPath.row
        
        if !follows.isEmpty && cell.tag == indexPath.item{
        
            _ = apicMainClient.request(APIMainRequests.getUser(login: follows[indexPath.row])).flatMap { (user) -> Single<UIImage> in
                
                DispatchQueue.main.async{
                   
                    cell.login.hideSkeleton()
                    cell.login.text = user.login
                }
                
                cell.userCallback = { [weak self] in
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    
                    let guestVC = storyboard.instantiateViewController(withIdentifier: "GuestVC") as! GuestVC
                    
                    guestVC.currentUser = self!.user
                    guestVC.guestUser = user
                    
                    
                    self?.navigationController?.pushViewController(guestVC, animated: true)
  
                }

                cell.followCallback = { [weak self] in
                    
                    var parameters = [String:Any]()
                    parameters["followee_login"] = user.login
                    
                    _ = self?.apicMainClient.request(APIMainRequests.follow(parameters: parameters))
                    
                        .subscribe {(following)  in
                            
                            switch following {
                            case .success(let message):
                                
                                self?.userFollowedUnfollowed.onNext(true)
                                
                                if message.message == APIResponseMessageText.followed.rawValue{
                                    
                                    DispatchQueue.main.async{
                                        
                                        cell.followBtn.hideSkeleton()
                                        cell.followBtn.setTitle("following", for: .normal)
                                        cell.followBtn.backgroundColor = .systemGray6
                                        
                                        
                                    }
                                    
                                }else if message.message == APIResponseMessageText.unfollowed.rawValue{
                                    
                                    switch self?.type {
                                    
                                    case .followers:
                                        
                                        DispatchQueue.main.async{
                                            
                                            cell.followBtn.hideSkeleton()
                                            cell.followBtn.setTitle("follow", for: .normal)
                                            cell.followBtn.backgroundColor = .systemBlue
                                            
                                        }
                                        
                                        
                                    case .followees:
                                        DispatchQueue.main.async{
                                            self?.follows.removeAll{ $0 == user.login! }
                                        }
                                    case .none:
                                        break
                                    }
                                    
                                    
                                }
                                
                                
                            case .failure(let error):
                                print(error.localizedDescription)
                            }
                            
                        }
                    .disposed(by: self!.bag)

                }

                return self.apicMainClient.request(APIMainRequests.checkFollow(follower_login: self.user!.login!, followee_login: user.login!)).flatMap { (message)  in
                    
                    if message.message == APIResponseMessageText.followed.rawValue{
                        
                        DispatchQueue.main.async{
                            
                            cell.followBtn.hideSkeleton()
                            cell.followBtn.setTitle("following", for: .normal)
                            cell.followBtn.backgroundColor = .systemGray6
                            
                            
                        }
                        
                    }else if message.message == APIResponseMessageText.unfollowed.rawValue{
                        
                        DispatchQueue.main.async{
                            
                            cell.followBtn.hideSkeleton()
                            cell.followBtn.setTitle("follow", for: .normal)
                            cell.followBtn.backgroundColor = .systemBlue
                            
                        }
                    }
                    
                    
                    
                    if user.image_id != nil {
                        
                        let pictureSize = UIHelper.calculatePixelSizeToDownload(imageViewHeight: cell.avatarDimensions!.height, imageViewWidth: cell.avatarDimensions!.width,imageHeight: user.image_height!, imageWidth: user.image_width!)
                        
                        let url = self.apiCloudinaryClient.generateResizedImageUrl(height: pictureSize.height, width: pictureSize.width, publicID: user.image_id!)
                        
                        
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
                            
                            cell.avatar.hideSkeleton()
                            cell.avatar.image = image
 
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
