//
//  AppDelegate.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import UIKit
import RxSwift
import FacebookCore
import IQKeyboardManagerSwift




@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarDelegate{

    var window: UIWindow?
    let bag = DisposeBag()
    var initialClient = APIMainClient()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
   
       ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.disabledDistanceHandlingClasses.append(ChatVC.self)
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        login()
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      return ApplicationDelegate.shared.application(app, open: url, options: options)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
   
        
          
    @objc func login() {
        
        let retrievedRefreshToken =  Tokens.retrieveTokenFromKeyChain(token_type: "refresh_token")
           
            if retrievedRefreshToken != nil {
                
               
                _ = initialClient.request(APIMainRequests.refreshToken())
                
                .subscribe {(gettingResponse) in
                    switch gettingResponse{
                    
                    case .success(_):
                        
                        DispatchQueue.main.async {
                            
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let tabBar = storyboard.instantiateViewController(withIdentifier: "tabBar")
                            self.window?.rootViewController = tabBar
                            self.window?.makeKeyAndVisible()
                        }
                        
                    case .failure(let error):
                        
                        if error.asAFError?.responseCode == 401{
                           
                           
                            DispatchQueue.main.async {
                                
                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC")
                                self.window?.rootViewController = loginVC
                                self.window?.makeKeyAndVisible()
                            }
                            
                        }
            
                                print(error.localizedDescription)
                    }
                }
                
                .disposed(by: bag)
                
                
            }else {
                
                DispatchQueue.main.async {
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC")
                    self.window?.rootViewController = loginVC
                    self.window?.makeKeyAndVisible()
                }
            }
        

            }
        }
        

           
        
        



