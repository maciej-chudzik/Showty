//
//  ErrorHandler.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

extension UIResponder {
    
    @objc func handleError(_ error: Error,
                           from viewController: UIViewController,
                           retryHandler: @escaping () -> ()) {
        
        DispatchQueue.main.async {
            
            guard let nextResponder = self.next else {
                return assertionFailure("""
            Unhandled error \(error) from \(viewController)
            """)
            }
            
            nextResponder.handleError(error, from: viewController, retryHandler: retryHandler)
            
        }
    }
}

extension UIViewController {
    func handleError(_ error: Error,
                     retryHandler: @escaping () -> Void) {
        handleError(error, from: self, retryHandler: retryHandler)
    }
}

extension AppDelegate {
    override func handleError(_ error: Error,
                              from viewController: UIViewController,
                              retryHandler: @escaping () -> Void) {
        
        ErrorHandler.determineErrorTypeAndPresentAlert(error: error, viewController: viewController, retryHandler: retryHandler)
        
    }
    
    struct ErrorHandler{
        
        static func determineErrorTypeAndPresentAlert(error: Error,viewController: UIViewController,retryHandler: @escaping () -> ()){
            
            if let afError = error as? AFError{
                
                if (500...599).contains(afError.responseCode!){
                    
                    DispatchQueue.main.async {
                        
                        let alert = UIAlertController(
                            title: "An error occured",
                            message: "Service temporary unavailable, please try again later",
                            preferredStyle: .alert
                        )
                        
                        alert.addAction(UIAlertAction(
                            title: "Dismiss",
                            style: .default
                        ))
                        
                        alert.addAction(UIAlertAction(
                            title: "Retry",
                            style: .default,
                            handler: { _ in retryHandler() }
                        ))
                        
                        viewController.present(alert, animated: true)
                    }
                    
                }
                
            }else if let serverError = error as? APIServerError{
                
                DispatchQueue.main.async {
                    
                    let alert = UIAlertController(
                        title: "An error occured",
                        message: serverError.localizedDescription,
                        preferredStyle: .alert
                    )
                    
                    alert.addAction(UIAlertAction(
                        title: "Dismiss",
                        style: .default
                    ))
                    
                    alert.addAction(UIAlertAction(
                        title: "Retry",
                        style: .default,
                        handler: { _ in retryHandler() }
                    ))
                    
                    viewController.present(alert, animated: true)
                }
            }
            
            
        }
        
    }
}
