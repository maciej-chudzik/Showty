//
//  UploadVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import YPImagePicker
import RxSwift
import GrowingTextView


class UploadVC: UIViewController, UINavigationControllerDelegate{
    
    
    @IBOutlet weak var postPicture: UIImageView!
    @IBOutlet weak var descriptionTxt: GrowingTextView!
    @IBOutlet weak var publishBtn: LoadingButton!
    @IBOutlet weak var addPhoto: UILabel!
    
    
    var apiMainClient = APIMainClient()
    var apiCloudinaryClient = APICloudinaryClient()
    let bag = DisposeBag()
    
    var changesMade: Bool = false
    
    var postToPublish = [String:Any]()
    var newPostAdded = PublishSubject<Bool>()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        publishBtn.isEnabled = false
        publishBtn.backgroundColor = .lightGray
     
        descriptionTxt.setBorder()
        
        postPicture.layer.cornerRadius = 10
        postPicture.clipsToBounds = true
        postPicture.addDashedBorder(withColor: UIColor.systemGray2, lineWidth: 5.0, lineDashPattern: [10,10])
      
        
        
        let postPictureTap = UITapGestureRecognizer(target: self, action: #selector (self.postPicturePick))
        postPictureTap.numberOfTapsRequired = 1
        
        let addPhotoTap = UITapGestureRecognizer(target: self, action: #selector (self.postPicturePick))
        addPhotoTap.numberOfTapsRequired = 1
        
        postPicture.isUserInteractionEnabled = true
        postPicture.addGestureRecognizer(postPictureTap)
        
        addPhoto.isUserInteractionEnabled = true
        addPhoto.addGestureRecognizer(addPhotoTap)
        
        
        
        let hideTap = UITapGestureRecognizer(target: self, action: #selector (keyboardWillhideTap))
        
        hideTap.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(hideTap)
    }
    
    @objc func keyboardWillhideTap(recognizer: UITapGestureRecognizer){
        
        self.view.endEditing(true)
        
    }
    
    func configureYPImagePicker() -> YPImagePickerConfiguration{
        
        var config = YPImagePickerConfiguration()
        config.isScrollToChangeModesEnabled = true
        config.onlySquareImagesFromCamera = true
        config.usesFrontCamera = false
        config.showsPhotoFilters = true
        config.shouldSaveNewPicturesToAlbum = false
        config.albumName = "Gallery"
        config.startOnScreen = YPPickerScreen.photo
        config.screens = [.library, .photo]
        config.showsCrop = .rectangle(ratio: 1.0)
        config.targetImageSize = YPImageSize.cappedTo(size: 1125.0)
        
        config.overlayView = UIView()
        config.hidesStatusBar = true
        config.hidesBottomBar = false
        config.preferredStatusBarStyle = UIStatusBarStyle.default
        config.bottomMenuItemSelectedTextColour = .systemBlue
        config.bottomMenuItemUnSelectedTextColour = .systemGray6
        config.maxCameraZoomFactor = 1.0
        
        return config
    }
    
    func configureYPImagePickerLibrary( config: inout YPImagePickerConfiguration){
        config.library.options = nil
        config.library.onlySquare = true
        config.library.isSquareByDefault = true
        config.library.minWidthForItem = nil
        config.library.mediaType = YPlibraryMediaType.photo
        config.library.defaultMultipleSelection = false
        config.library.maxNumberOfItems = 1
        config.library.minNumberOfItems = 1
        config.library.numberOfItemsInRow = 4
        config.library.spacingBetweenItems = 1.0
        config.library.skipSelectionsGallery = false
        config.library.preselectedItems = nil
        
        
    }
    
    
    @objc func postPicturePick(recognizer: UITapGestureRecognizer){
        
        var configuration = configureYPImagePicker()
        configureYPImagePickerLibrary(config: &configuration)
        let YPpicker = YPImagePicker(configuration: configuration)
        
        
        YPpicker.didFinishPicking { [weak self] items, _ in
            if let photo = items.singlePhoto {
                
                let widthInPixels = photo.image.size.width * photo.image.scale
                let heightInPixels = photo.image.size.height * photo.image.scale
                
                self?.postToPublish["image_height"] = Int(heightInPixels)
                self?.postToPublish["image_width"] = Int(widthInPixels)
                
                self?.addPhoto.isHidden = true
                
                self?.postPicture.removeDashedBorder()
                
                self?.postPicture.image = photo.image
                
                self?.publishBtn.isEnabled = true
                
                self?.publishBtn.backgroundColor = .systemBlue
                
                self?.postPicture.isUserInteractionEnabled = true
                
                self?.changesMade = true
                
                
                
            }
            YPpicker.dismiss(animated: true, completion: nil)
        }
        present(YPpicker, animated: true, completion: nil)
    }
    
    
    @IBAction func publish(_ sender: Any) {
        
        let button = sender as! LoadingButton
        button.showLoading()
        
        
        self.view.endEditing(true)
        
        if descriptionTxt.text != nil {
            
            postToPublish["description"] = descriptionTxt.text
            changesMade = true
            
        }else{
            
            postToPublish["description"] = ""
            changesMade = true
        }
        
        
        
        guard changesMade else {
            UIHelper.displayAlert(viewController: self, message: "Please choose the photo to post")
            
            return
        }
        
        let _ = self.apiCloudinaryClient.uploadImage(call: (APICloudinary.uploadImage(imageData: (self.postPicture.image?.jpegData(compressionQuality: 1.0))!))).flatMap { [weak self] result -> Single<APIResponseMessage> in
            
            
            
            self!.postToPublish["image_id"] = result.public_id!
            return self!.apiMainClient.request(APIMainRequests.publishPost(parameters: self!.postToPublish))
            
        }
        
        .subscribe { [unowned self] (publishingPost)  in
            
            
            switch publishingPost {
            case .success(let message):
                

                DispatchQueue.main.sync{
                    
                    button.hideLoading()
                    
                    
                    UIHelper.displayAlert(viewController: self, message: message.message!, title: nil, completion: { (action) in
                        if action.style == .cancel{
                            
                            
                            self.newPostAdded.onNext(true)
                            
                            self.viewDidLoad()
                            self.tabBarController?.selectedIndex = 0
                            
                            self.dismiss(animated: true, completion: nil)
                            
                        }})
                }
                
            case .failure(let error):
                print(error.localizedDescription)
            }}
        
        .disposed(by: self.bag)
 
    }
   
}
  
