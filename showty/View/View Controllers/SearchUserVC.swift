//
//  SearchUserVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SkeletonView

class SearchUserVC: UIViewController {
    
  
    @IBOutlet weak var tableView: UITableView!
    
    let apiMainClient = APIMainClient()
    let bag = DisposeBag()
    let apiCloundinaryClient = APICloudinaryClient()
    
    var addSentMessageToConversationsCallback: ((CustomMessage)->())?
    var updateReadStatusCallback: ((Int)->())?
    var pushMessageToChildVC: ((MessageTypeExtended)->())?

    
    private let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "search user"

        return searchController
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
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
            return APIMainRequests.searchUser(parameters: parameters)}
        .flatMap { request -> Observable<[SearchResult]> in
            return self.apiMainClient.requestSearch(request)
        }
        let empty = searchTextChanged
        .filter{$0 != ""}
        .map { _ in return [SearchResult]() }
        let searches = Observable.of(empty, changedWithRequests).merge()
        
        searches.bind(to: tableView.rx.items(cellIdentifier: "SearchCell", cellType: SearchCell.self)){ index, model, cell in
                
                    _ = self.apiMainClient.request(APIMainRequests.getUser(login: model.search_result!)).flatMap { (user) -> Single<UIImage> in
                        
                        if user.image_id != nil {
                                
                            let pictureSize = UIHelper.calculatePixelSizeToDownload(imageViewHeight: cell.avatarDimensions!.height, imageViewWidth: cell.avatarDimensions!.width, imageHeight: user.image_height!, imageWidth: user.image_width!)
                                    
                                    let url = self.apiCloundinaryClient.generateResizedImageUrl(height: pictureSize.height, width: pictureSize.width, publicID: user.image_id!)
                                    
                                
                                    return self.apiCloundinaryClient.downloadImage(call: CloudinaryCall(url: url))
                                
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
                    .disposed(by: self.bag)
                        
           
            
   
            cell.item.text = model.search_result

        }
        .disposed(by: bag)

        tableView.rx.modelSelected(SearchResult.self)
        .subscribe(onNext: {  [weak self] model in

           
             DispatchQueue.main.async{
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                      
                let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatVC") as! ChatVC
                
                chatVC.guest = model.search_result!
                
                chatVC.addSentMessageToConversationsCallback = self?.addSentMessageToConversationsCallback
                chatVC.updateReadStatusCallback = self?.updateReadStatusCallback
                
                let conversationVC  = self?.navigationController?.children[0] as! ConversationsVC
                
                conversationVC.pushMessageToChildVC = {[weak chatVC]
                    msg in
                    
                    chatVC?.insertMessage(msg)
                    
                }
            
                self?.navigationController?.pushViewController(chatVC, animated: true)
            }

        })
        
        .disposed(by: bag)
        
    }

}
