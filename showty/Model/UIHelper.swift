//
//  UIHelper.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import Foundation
import UIKit

class UIHelper {
    
    static func displayAlert(viewController: UIViewController, message: String, title: String? = nil, completion: ((UIAlertAction) -> Void)? = nil) {
        
        var title = title
        if title == nil{
            
            title = ""
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .cancel, handler: completion)
        alertController.addAction(OKAction)
        DispatchQueue.main.async {
            
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    static func checkTextFieldsEmpty(viewcontroller: UIViewController, view: UIView, checkAllFields: Bool = true, textFields: [UITextField]? = nil){
        
        var viewsArray = [UIView]()
        
        if checkAllFields {
            
            viewsArray = view.subviews
            
        }else{
            
            viewsArray = textFields!
            
        }
        
        for textField in viewsArray{
            if let textField = textField as? UITextField {
                
                textField.layer.borderWidth = 0
                
                if (textField.text?.isEmpty)!{

                    textField.layer.borderWidth = 0.5
                    textField.layer.cornerRadius = 5
                    
                    textField.layer.borderColor = UIColor.red.cgColor
                    displayAlert(viewController: viewcontroller, message: "Textfields marked red cannot be empty.")
                    
                    return

                }
                
            }
        }
        
    }

    static func isEmailCorrect(email: String) -> Bool{
        
        let regular: String
        regular = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", regular).evaluate(with: email)
        
    }
    
    static func getVisibleViewController(_ rootViewController: UIViewController?) -> UIViewController? {
        var rootVC = rootViewController
        if rootVC == nil {
            rootVC = UIApplication.shared.windows.filter {$0.isKeyWindow}.first!.rootViewController
        }
        
        if rootVC?.presentedViewController == nil {
            return rootVC
        }
        
        if let presented = rootVC?.presentedViewController {
            if presented.isKind(of: UINavigationController.self) {
                let navigationController = presented as! UINavigationController
                return navigationController.viewControllers.last!
            }
            
            if presented.isKind(of: UITabBarController.self) {
                let tabBarController = presented as! UITabBarController
                return tabBarController.selectedViewController!
            }
            
            return getVisibleViewController(presented)
        }
        return nil
    }
    
    
    static func calculatePixelSizeToDownload(imageViewHeight: CGFloat, imageViewWidth: CGFloat, imageHeight: Int, imageWidth: Int)->(height: Int,width: Int){

        let imageViewHeight = Int(imageViewHeight)
        let imageViewWidth = Int(imageViewWidth)
        
        
        if imageViewWidth !=  imageViewHeight {
            
            return (imageViewHeight * Int(UIScreen.main.scale),imageViewWidth * Int(UIScreen.main.scale))
            
        }

        if imageWidth > imageHeight {
            
            let multiplier = imageWidth/imageHeight
            
            return (imageViewHeight * Int(UIScreen.main.scale),imageViewWidth * Int(UIScreen.main.scale) * multiplier)
            
            
        }else if imageWidth < imageHeight {
            
            let multiplier = imageHeight/imageWidth
            
            return (imageViewHeight * Int(UIScreen.main.scale) * multiplier,imageViewWidth * Int(UIScreen.main.scale))
            
        }else {
            
            return (imageViewHeight * Int(UIScreen.main.scale),imageViewWidth * Int(UIScreen.main.scale))
            
        }
        
    }
    
    
    static func calculateTimeDiff(dateInString: String) -> String?{
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSzz"
        
        guard let formattedDate = dateFormatter.date(from: dateInString) else {return nil}
        
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: formattedDate, to: now, options: [])
        
        if difference.second! <= 0 && difference.minute! == 0 && difference.hour! == 0 &&  difference.day! == 0 && difference.weekOfMonth! == 0{
            
            return "now"
            
        }else if  difference.second! > 0 && difference.minute! == 0 && difference.hour! == 0 &&  difference.day! == 0 && difference.weekOfMonth! == 0{
            
            return  "\(difference.second!)s"
            
        }else if difference.minute! > 0 && difference.hour! == 0 &&  difference.day! == 0 && difference.weekOfMonth! == 0{
            
            return  "\(difference.minute!)m"
            
        }else if difference.hour! > 0 && difference.day! == 0 && difference.weekOfMonth! == 0{
            
            return "\(difference.hour!)h"
            
        }else if  difference.day! > 0 && difference.weekOfMonth! == 0{
            
            return "\(difference.day!)d"
            
        }else if difference.weekOfMonth! > 0 {
            
            return "\(difference.weekOfMonth!)w"
            
        }else{
            return nil
        }
        
        
    }
    
    
    
}


    

