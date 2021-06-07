//
//  SearchVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SkeletonView

class SearchVC: UIViewController {
    
  
    
    @IBOutlet weak var tableView: UITableView!
    
    
    let apiMainClient = APIMainClient()
    let bag = DisposeBag()
    let apiCloudinaryClient = APICloudinaryClient()

    
    private let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "search user or hashtag"

        return searchController
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationController?.navigationBar.backgroundColor = .systemBackground
        configureBinding()
      
    }

    private func configureBinding() {
        
        let searchTextChanged = searchController.searchBar.rx.text.orEmpty.asObservable()
      
        let changedWithRequests = searchTextChanged.skip(1)
        .distinctUntilChanged()
        .filter{$0 != ""}
        .map { ($0).lowercased() }
        .map {
            var parameters =  [String:Any]()
            parameters["keyword"] = $0
            return APIMainRequests.search(parameters: parameters)}
        .flatMap { request -> Observable<[SearchResult]> in
            return self.apiMainClient.requestSearch(request)
        }
        let empty = searchTextChanged
        .filter{$0 != ""}
        .map { _ in return [SearchResult]() }
        let searches = Observable.of(empty, changedWithRequests).merge()
        
        searches.bind(to: tableView.rx.items(cellIdentifier: "SearchCell", cellType: SearchCell.self)){ index, model, cell in
                
            switch model.type {
                
                case "hashtag":
                    cell.avatar.isHidden = true
                
                
                case "user":
                    cell.avatar.isHidden = false
                    cell.avatar.showAnimatedSkeleton(usingColor: .systemGray6, animation: nil, transition: SkeletonTransitionStyle.none)
                
                    _ = self.apiMainClient.request(APIMainRequests.getUser(login: model.search_result!)).flatMap { (user) -> Single<UIImage> in
                        
                        if user.image_id != nil {
                                
                            let pictureSize = UIHelper.calculatePixelSizeToDownload(imageViewHeight: cell.avatarDimensions!.height,imageViewWidth: cell.avatarDimensions!.width, imageHeight: user.image_height!, imageWidth: user.image_width!)
                                    
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
                    .disposed(by: self.bag)
                        
                default:
                    break
            
            }
            
   
            cell.item.text = model.search_result

        }
        .disposed(by: bag)


        
        
            tableView.rx.modelSelected(SearchResult.self)
            .subscribe(onNext: {  [weak self] model in
                switch model.type {
                
                case "hashtag":
                    
                    _ = self?.apiMainClient.request(APIMainRequests.loggedUser())
                                         
                    .subscribe { [unowned self] (gettingCurrentUser)  in
                                             switch gettingCurrentUser {
                                               
                                            case .success(let currentUser):
                                                
                                                 DispatchQueue.main.async{
                                                let hashtagVC = self?.storyboard?.instantiateViewController(withIdentifier: "HashtagVC") as! HashtagVC
                                                hashtagVC.hashtag = String(model.search_result!.dropFirst())
                                                hashtagVC.currentuser = currentUser
                                                self?.navigationController?.pushViewController(hashtagVC, animated: true)
                                                
                                                }
                                
                                            case .failure(let error):
                                                                         
                                                print(error.localizedDescription)
                                                                         
                                            }}
                                                                     
                                                                     
                    .disposed(by: self!.bag)
                                                               

                
                case "user":
                    
                    _ = self?.apiMainClient.request(APIMainRequests.loggedUser())
                      
                      .subscribe { [unowned self] (gettingCurrentUser)  in
                          switch gettingCurrentUser {
                            
                          case .success(let currentUser):
                            
                            _ = self?.apiMainClient.request(APIMainRequests.getUser(login: model.search_result!))
                                                  
                                                  .subscribe { [unowned self] (gettinUser)  in
                                                      switch gettinUser {
                                                        
                                                      case .success(let gotUser):
                                                        
                                                                                
                                                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                                     DispatchQueue.main.async{
                                                        let guestVC = storyboard.instantiateViewController(withIdentifier: "GuestVC") as! GuestVC
                                                        
                                                        guestVC.currentUser = currentUser
                                                        guestVC.guestUser = gotUser
                                                    
                                                        self?.navigationController?.pushViewController(guestVC, animated: true)
                                                        }
  
                                                      case .failure(let error):
                                                          
                                                          print(error.localizedDescription)
                                                          
                                                          
                                                      }}
                                                      
                                                      
                                                    .disposed(by: self!.bag)
                            
                
                          case .failure(let error):
                              
                              print(error.localizedDescription)
                              
                              
                          }}
                          
                          
                        .disposed(by: self!.bag)

                default:
                    break
                    
                }
            })
            .disposed(by: bag)
    }
    


}
