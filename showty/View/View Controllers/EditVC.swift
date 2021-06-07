//
//  EditVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import RxSwift
import YPImagePicker
import GrowingTextView


class EditVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    deinit{
        print("EditVC deinit")
    }
    
    @IBOutlet weak var avatar: RoundImageV!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var fullnameTxt: UITextField!
    @IBOutlet weak var descriptionTxt: GrowingTextView!
    @IBOutlet weak var emailTxt: UITextField!
    @IBOutlet weak var genderTxt: UITextField!
    @IBOutlet weak var telephoneTxt: UITextField!

    @objc var genderPicker: UIPickerView!
    @objc let genders = ["male", "female", "nonbinary"]
    
    let apiMainClient =  APIMainClient()
    let apiCloudinaryClient = APICloudinaryClient()
    let bag = DisposeBag()
   
    var currentUser: User?
    var updateNeeded: Bool = false
    var imagePicked: Bool = false
    
    var userToUpdate = [String:Any]()
    
    var userDataUpdated = PublishSubject<Bool>()
    
    var updatingUser: PrimitiveSequence<SingleTrait, APIResponseMessage>?
    
    var avatarDimensions: (height: CGFloat, width: CGFloat)?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        avatarDimensions = (avatar.bounds.height, avatar.bounds.width)
                
        let hideTap = UITapGestureRecognizer(target: self, action: #selector (keyboardWillhideTap))
        
        hideTap.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(hideTap)
        
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector (avatarPick))
        avatarTap.numberOfTapsRequired = 1
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(avatarTap)
        
        descriptionTxt.setBorder()
        
        setMaxCharsLimiters()
        configureGenderPicker()
        configureScrollView()
        
        loadUserInformation()
      
    }
    
    
    private func setMaxCharsLimiters(){
        
        fullnameTxt.rx.text.asObservable()
           
            .subscribe(onNext: { [unowned self] (text) in
            if let text = self.fullnameTxt.text {
                self.fullnameTxt.text = String(text.prefix(80))
            }
        }).disposed(by: bag)
        
        genderTxt.rx.text.asObservable()
           
            .subscribe(onNext: { [unowned self] (text) in
            if let text = self.genderTxt.text {
                self.genderTxt.text = String(text.prefix(10))
            }
        }).disposed(by: bag)
        
        emailTxt.rx.text.asObservable()
           
            .subscribe(onNext: { [unowned self] (text) in
            if let text = self.emailTxt.text {
                self.emailTxt.text = String(text.prefix(80))
            }
        }).disposed(by: bag)
        
        
        telephoneTxt.rx.text.asObservable()
           
            .subscribe(onNext: { [unowned self] (text) in
            if let text = self.telephoneTxt.text {
                self.telephoneTxt.text = String(text.prefix(80))
            }
        }).disposed(by: bag)
        
    }
    
    private func configureGenderPicker(){
        
        genderPicker = UIPickerView()
        genderPicker.dataSource = self
        genderPicker.delegate = self
        genderPicker.backgroundColor = UIColor.systemGroupedBackground
        genderTxt.inputView = genderPicker
        
    }
    
    private func configureScrollView(){
        
        scrollView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        
        scrollView.contentSize.height = self.view.frame.height
        
    }
    
    
    @objc func avatarPick (recognizer: UITapGestureRecognizer){
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {


        if let image = info[.editedImage] as? UIImage{
            avatar.image = image
            imagePicked = true
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    

    @objc func keyboardWillhideTap(recognizer: UITapGestureRecognizer){
        
        self.view.endEditing(true)

    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return genders.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return genders[row]
        
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        genderTxt.text = genders[row]
        self.view.endEditing(true)
    
    }
    
    @objc private func loadUserInformation() {
     

         _ = apiMainClient.request(APIMainRequests.loggedUser()).flatMap {[weak self](user) -> Single<UIImage> in
            
            self?.currentUser = user
            
            if  self?.currentUser!.image_id != nil {
                
             
                
                let pictureSize = UIHelper.calculatePixelSizeToDownload(imageViewHeight: self!.avatarDimensions!.height, imageViewWidth: self!.avatarDimensions!.width, imageHeight: user.image_height!, imageWidth: user.image_width!)
                    
                    
                let url = self?.apiCloudinaryClient.generateResizedImageUrl(height: pictureSize.height, width: pictureSize.width, publicID: user.image_id!)
                
            
                
                return self!.apiCloudinaryClient.downloadImage(call: CloudinaryCall(url: url!))
                
            }else{
            
                let image = UIImage(named: "avatar.png")
                
                return Single.just(image!)
            }
            
            
            
            }
        
         .subscribe { [weak self] (gettingImage)  in
            switch gettingImage {
            case .success(let image):
                
                
                
                DispatchQueue.main.async{
                    
                    UIView.transition(with: self!.avatar,
                                      duration:0.5,
                                      options: .transitionCrossDissolve,
                                      animations: { self?.avatar.image = image },
                                      completion: nil)
                    
                }
                
                
                
                DispatchQueue.main.async {
                    
                    
                    self?.fullnameTxt.text = self?.currentUser?.fullname
                    self?.emailTxt.text = self?.currentUser?.email
                    self?.descriptionTxt.text = self?.currentUser?.description
                    self?.telephoneTxt.text = self?.currentUser?.telephone
                    self?.genderTxt.text = self?.currentUser?.gender
                }
                
            case .failure(let error):
                print(error.localizedDescription)
            }}
            
            .disposed(by: bag)

       
        
    }
    
    
    @IBAction private func save(_ sender: Any) {
        
        
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let barButton = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.setRightBarButton(barButton, animated: true)
        activityIndicator.startAnimating()
        
        
        self.view.endEditing(true)
        
        if !UIHelper.isEmailCorrect(email: emailTxt.text!){
            
            DispatchQueue.main.async{
                UIHelper.displayAlert(viewController: self, message: "Please provide correct email!")
            }
            return
        }
        
        if fullnameTxt.text!.isEmpty && currentUser?.fullname != ""{
            
            userToUpdate["fullname"] = ""
            updateNeeded = true
            
        }else if fullnameTxt.text! != currentUser?.fullname{
            
            userToUpdate["fullname"] = fullnameTxt.text!
            updateNeeded = true
        }
        
        
        if emailTxt.text!.isEmpty {
            DispatchQueue.main.async{
                UIHelper.displayAlert(viewController: self, message: "Please provide email!")
            }
        }else if emailTxt.text! != currentUser?.email{
            
            userToUpdate["email"] = emailTxt.text!
            updateNeeded = true
        }
        
        
        if descriptionTxt.text!.isEmpty && currentUser?.description != ""{
            
            userToUpdate["description"] = nil
            updateNeeded = true
            
        }else if descriptionTxt.text! != currentUser?.description{
            
            userToUpdate["description"] = descriptionTxt.text!
            updateNeeded = true
        }
        
        
        if genderTxt.text!.isEmpty && currentUser?.gender != "" {
            
            userToUpdate["gender"] = ""
            updateNeeded = true
            
        }else if genderTxt.text! != currentUser?.gender{
            
            userToUpdate["gender"] = genderTxt.text!
            updateNeeded = true
        }
        
        if telephoneTxt.text!.isEmpty && currentUser?.telephone != ""{
            
            userToUpdate["telephone"] = ""
            updateNeeded = true
            
        }else if telephoneTxt.text! != currentUser?.telephone{
            
            userToUpdate["telephone"] = telephoneTxt.text!
            updateNeeded = true
        }
        
        guard updateNeeded || imagePicked else {
            DispatchQueue.main.async{
                UIHelper.displayAlert(viewController: self, message: "No changes were made profile won't be updated")
                activityIndicator.stopAnimating()
            }
            return
        }
        
        if imagePicked {
            
            
            self.updatingUser  = self.apiCloudinaryClient.uploadImage(call: (APICloudinary.uploadImage(imageData: self.avatar.image!.pngData()!))).flatMap { [weak self](result) in
                
                self!.userToUpdate["image_id"] = result.public_id!
                return self!.apiMainClient.request(APIMainRequests.updateUser(parameters: self!.userToUpdate))
            }
            
        }else{
            self.updatingUser = self.apiMainClient.request(APIMainRequests.updateUser(parameters: self.userToUpdate))
            
        }
        
        
        updatingUser?.subscribe { [unowned self] (updatingUser)  in
            switch updatingUser {
            case .success(let message):
                
                DispatchQueue.main.async{
                    
                    UIHelper.displayAlert(viewController: self, message: message.message!, title: nil, completion: { (action) in
                                            if action.style == .cancel{
                                                
                                                activityIndicator.stopAnimating()
                                                self.userDataUpdated.onNext(true)
                                                self.dismiss(animated: true, completion: nil)
                                                
                                            }})
                }
                
            case .failure(let error):
                print(error.localizedDescription)
            }}
            
            .disposed(by: self.bag)
        
    }
    

    

    @IBAction private func cancel(_ sender: Any) {
        
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
}

