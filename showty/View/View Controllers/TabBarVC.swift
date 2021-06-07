//
//  TabBarVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import RxSwift

class TabBarVC: UITabBarController, UITabBarControllerDelegate {
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.tabBar.tintColor = .label
        self.tabBar.barTintColor = .systemBackground
        self.tabBar.isTranslucent = true
        self.delegate = self
        
    }
    

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        
        let newVCs: [UINavigationController]? = tabBarController.viewControllers?.map{
            
            
            guard $0 == viewController else{
                
                let navVC = $0 as! UINavigationController
                
                navVC.children.first?.view = nil
                
                return $0 as! UINavigationController
                
            }
            
            return $0 as! UINavigationController

        }

        tabBarController.setViewControllers(newVCs, animated: false)
    }
    
 
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool{
        
        
        weak var navigationVC = tabBarController.viewControllers![0] as? NavigationVC
        
        
        if let homeVC = navigationVC?.children.first{
            
            let homeVC = homeVC as! HomeVC
            
            if let uploadVC = viewController.children.first as? UploadVC{
                
                uploadVC.newPostAdded.subscribe {(event) in
                    
                    guard event.element == true else { return }
                    
                    _ = homeVC.apiMainClient.request(APIMainRequests.getNewestPost()).flatMap {(newestPost) -> Single<Posts> in
                        
                        homeVC.posts.insert(newestPost, at: 0)
                        
                        homeVC.postsImageIDs.insert(newestPost.image_id!, at: 0)
                        
                        return homeVC.apiMainClient.request(APIMainRequests.countUserPosts(login: homeVC.currentuser!.login!))
                        
                    }
                    
                    .subscribe {(gettingCount) in
                        
                        switch gettingCount{
                        
                        case .success(let posts):
                            
                            DispatchQueue.main.async{
                                
                                homeVC.header?.noPosts.text = "\(posts.posts_count! )"
                                
                            }
                            
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                        
                    }
                    
                    .disposed(by: homeVC.bag)
                    
                    
                    
                }.disposed(by: uploadVC.bag)
            }
            
            
        }
        
        return true
    }
    
    
    
}
    
   


