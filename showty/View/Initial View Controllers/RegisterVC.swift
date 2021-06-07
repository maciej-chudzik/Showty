//
//  RegisterVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import Alamofire
import RxSwift
import RxCocoa
import YPImagePicker
import GrowingTextView

class RegisterVC: UIViewController, UINavigationControllerDelegate{
    
    
    @IBOutlet weak var emailTxt: UITextField!
    @IBOutlet weak var fullnameTxt: UITextField!
    @IBOutlet weak var loginTxt: UITextField!
    @IBOutlet weak var passwordTxt: UITextField!
    @IBOutlet weak var avatar: RoundImageV!
    @IBOutlet weak var repeatPasswordTxt: UITextField!
    @IBOutlet weak var descriptionTxt: GrowingTextView!
    @IBOutlet weak var registerBtn: LoadingButton!
    @IBOutlet weak var cancelBtn: CustomButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var addPhotoLbl: UILabel!
    
    let apiMainClient = APIMainClient()
    let apiCloudinaryClient = APICloudinaryClient()
    let bag = DisposeBag()
    
    var avatarPicked = false
    var userToRegister = [String:Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector (avatarPick))
        avatarTap.numberOfTapsRequired = 1
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(avatarTap)
        
        let addPhotoTap = UITapGestureRecognizer(target: self, action: #selector (avatarPick))
        addPhotoTap.numberOfTapsRequired = 1
        addPhotoLbl.isUserInteractionEnabled = true
        addPhotoLbl.addGestureRecognizer(addPhotoTap)
        
        avatar.addDashedBorder(withColor: UIColor.systemGray2, lineWidth: 5.0, lineDashPattern: [10,10])
        
        configureScrollView()
        descriptionTxt.setBorder()
        setMaxCharsLimiters()
        
        
    }
    
    private func setMaxCharsLimiters(){
        
        loginTxt.rx.text.asObservable()
            
            .subscribe(onNext: { [unowned self] (text) in
                if let text = self.loginTxt.text {
                    self.loginTxt.text = String(text.prefix(20))
                }
            }).disposed(by: bag)
        
        passwordTxt.rx.text.asObservable()
            
            .subscribe(onNext: { [unowned self] (text) in
                if let text = self.passwordTxt.text {
                    self.passwordTxt.text = String(text.prefix(32))
                }
            }).disposed(by: bag)
        
        repeatPasswordTxt.rx.text.asObservable()
            
            .subscribe(onNext: { [unowned self] (text) in
                if let text = self.repeatPasswordTxt.text {
                    self.repeatPasswordTxt.text = String(text.prefix(32))
                }
            }).disposed(by: bag)
        
        emailTxt.rx.text.asObservable()
            
            .subscribe(onNext: { [unowned self] (text) in
                if let text = self.emailTxt.text {
                    self.emailTxt.text = String(text.prefix(80))
                }
            }).disposed(by: bag)
        
        fullnameTxt.rx.text.asObservable()
            
            .subscribe(onNext: { [unowned self] (text) in
                if let text = self.fullnameTxt.text {
                    self.fullnameTxt.text = String(text.prefix(80))
                }
            }).disposed(by: bag)
        
    }
    
    private func configureScrollView(){
        
        scrollView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        
        scrollView.contentSize.height = self.view.frame.height
        
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
    
    @objc func avatarPick (recognizer: UITapGestureRecognizer){
        
        var configuration = configureYPImagePicker()
        configureYPImagePickerLibrary(config: &configuration)
        let YPpicker = YPImagePicker(configuration: configuration)
        
        
        YPpicker.didFinishPicking { [weak self] items, _ in
            if let photo = items.singlePhoto {
                
                
                let widthInPixels = photo.image.size.width * photo.image.scale
                let heightInPixels = photo.image.size.height * photo.image.scale
                
                
                
                self?.userToRegister["image_height"] = Int(heightInPixels)
                self?.userToRegister["image_width"] = Int(widthInPixels)
                
                self?.addPhotoLbl.isHidden = true
                
                self?.avatar.removeDashedBorder()
                self?.avatar.image = photo.image
                
                self?.avatar.isUserInteractionEnabled = true
                
                self?.avatarPicked = true
                
                
                
            }
            YPpicker.dismiss(animated: true, completion: nil)
        }
        present(YPpicker, animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    @IBAction func register(_ sender: LoadingButton) {
        
        self.view.endEditing(true)
        
        sender.showLoading()
        
        let textFieldsToCheck: [UITextField] = [loginTxt, passwordTxt, repeatPasswordTxt, emailTxt, fullnameTxt]
        
        UIHelper.checkTextFieldsEmpty(viewcontroller: self, view: self.view, checkAllFields: false, textFields: textFieldsToCheck)
        
        userToRegister["login"] = loginTxt.text!.lowercased()
        
        
        
        if passwordTxt.text!.count < 4 {
            
            sender.hideLoading()
            
            UIHelper.displayAlert(viewController: self, message: "Password is to short. Minimum 4 charaters")
            return
        }
        
        
        if passwordTxt.text != repeatPasswordTxt.text {
            
            sender.hideLoading()
            
            UIHelper.displayAlert(viewController: self, message: "Passwords do not match!")
            return
        }
        
        userToRegister["password"] = passwordTxt.text!
        userToRegister["fullname"] = fullnameTxt.text!
        
        
        if !UIHelper.isEmailCorrect(email: emailTxt.text!){
            
            sender.hideLoading()
            
            UIHelper.displayAlert(viewController: self, message: "Please provide correct email!")
            
            return}
        userToRegister["email"] = emailTxt.text!
        
        if descriptionTxt.text != "description" && descriptionTxt.text != ""{
            userToRegister["description"] = descriptionTxt.text!
        }
        
        if avatarPicked {
            let _ =  apiCloudinaryClient.uploadImage(call: APICloudinary.uploadImage(imageData: (avatar.image?.pngData())!)).flatMap { (response) -> Single<APIResponseMessage> in
                
                self.userToRegister["image_id"] = response.public_id
                
                
                return self.apiMainClient.request(APIMainRequests.register(parameters: self.userToRegister))
                
            }
            
            .subscribe{ (subscription) in
                
                switch subscription {
                
                case .success(let message):
                    
                    UIHelper.displayAlert(viewController: self, message: message.message!)
                    
                    DispatchQueue.main.async {
                        sender.hideLoading()
                        
                        
                        let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                        appDelegate.window?.rootViewController = loginVC
                    }
                    
                    
                case .failure(let error):
                    
                    UIHelper.displayAlert(viewController: self, message: error.localizedDescription)
                    
                }}
            .disposed(by: self.bag)
            
            
        }else {
            
            let  _ = apiMainClient.request(APIMainRequests.register(parameters: userToRegister))
                
                .subscribe{ (subscription) in
                    
                    switch subscription {
                    
                    case .success(let message):
                        
                        UIHelper.displayAlert(viewController: self, message: message.message!)
                        
                        DispatchQueue.main.async {
                            sender.hideLoading()
                            
                            
                            let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                            let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                            appDelegate.window?.rootViewController = loginVC
                        }
                        
                    case .failure(let error):
                        
                        UIHelper.displayAlert(viewController: self, message: error.localizedDescription)
                        
                    }}
                .disposed(by: bag)
            
        }
        
    }
    
    
    
    
    
    @IBAction func cancel(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
}

    
