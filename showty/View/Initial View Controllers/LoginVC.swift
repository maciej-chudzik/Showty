//
//  LoginVC.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import RxSwift
import FacebookLogin

class LoginVC: UIViewController, LoginButtonDelegate, UITextFieldDelegate{
    
    
    @IBOutlet weak var usernameTxt: UITextField!
    @IBOutlet weak var passwordTxt: UITextField!
    @IBOutlet weak var loginBtn: LoadingButton!
    @IBOutlet weak var registerBtn: CustomButton!
    @IBOutlet weak var forgotPwBtn: UIButton!
    @IBOutlet weak var facebookLoginBtn: FBLoginButton!
    
    let apiMainClient = APIMainClient()
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        facebookLoginBtn.permissions = ["email", "public_profile"]
        facebookLoginBtn.delegate = self
        self.passwordTxt.delegate = self
        
    }
    
    
    @IBAction func login(_ sender: LoadingButton) {
        
        
        self.view.endEditing(true)
        
        UIHelper.checkTextFieldsEmpty(viewcontroller: self, view: self.view)
        
        sender.showLoading()
        
        
        _ = apiMainClient.request(APIMainRequests.login(login: usernameTxt.text!.lowercased(), password: passwordTxt.text!))
            
            .subscribe { (downloadingTokens) in
                switch downloadingTokens {
                case .success(let tokens):
                    if tokens.saveTokenToKeyChain(token_type: "access_token"), tokens.saveTokenToKeyChain(token_type: "refresh_token"){
                        
                        
                        
                        
                        DispatchQueue.main.async {
                            
                            UserDefaults.standard.setValue(self.usernameTxt.text!.lowercased(), forKey: "host")
                            
                            sender.hideLoading()
                            
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            
                            let tabBar = storyboard.instantiateViewController(withIdentifier: "tabBar")
                            
                            let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                            
                            appDelegate.window?.setRootViewController(tabBar, options: UIWindow.TransitionOptions(direction: .toRight))
                            
                        }
                        
                    }
                    
                case .failure(let error):
                    
                    UIHelper.displayAlert(viewController: self, message: error.localizedDescription)
                    
                    DispatchQueue.main.async {
                        sender.hideLoading()
                        self.usernameTxt.text = ""
                        self.passwordTxt.text = ""
                        
                    }
                    return
                    
                }}
            
            .disposed(by: bag)
        
    }
    
    func loginButtonWillLogin(_ loginButton: FBLoginButton) -> Bool {
        
        loginButton.setTitle("Signing in...", for: .selected)
        
        return true
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        if let result = result {
            
            if result.isCancelled{
                
                return
            }
        }
        
        
        if error == nil{
            
            
            _ = apiMainClient.request(APIMainRequests.facebookLogin(facebook_access_token: (result?.token!.tokenString)!))
                
                .subscribe { (gettingFBLoggingResponse) in
                    switch gettingFBLoggingResponse {
                    case .success(let facebookLoginResponse):
                        
                        if facebookLoginResponse.tokens!.saveTokenToKeyChain(token_type: "access_token"), facebookLoginResponse.tokens!.saveTokenToKeyChain(token_type: "refresh_token"){
                            
                            if facebookLoginResponse.mergeable! {
                                
                                
                            }else{
                                
                                DispatchQueue.main.async {
                                    
                                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                    
                                    let tabBar = storyboard.instantiateViewController(withIdentifier: "tabBar")
                                    
                                    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                                    
                                    appDelegate.window?.setRootViewController(tabBar, options: UIWindow.TransitionOptions(direction: .toRight))
                                }
                            }
                            
                            
                        }
                    case .failure(let error):
                        
                        UIHelper.displayAlert(viewController: self, message: error.localizedDescription)
                        return
                        
                    }
                }
                .disposed(by: bag)
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        loginButton.setTitle("Signed out", for: .normal)
    }
    
}
