//
//  APICloudinaryClient.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import Foundation
import Cloudinary
import RxSwift




class APICloudinaryClient{
    
    let cloudinary: CLDCloudinary
    
    deinit{
        
        print("APICloudinaryClient deinit")
    }
    
    
    init(){
        
        let config = CLDConfiguration(cloudName: PlistReader.shared.getValue(nameOfFile: "Info", nameOfKey: "CLDCloudName") as! String, apiKey: (PlistReader.shared.getValue(nameOfFile: "Info", nameOfKey: "CLDApiKey") as! String))
        self.cloudinary = CLDCloudinary(configuration: config)
        
        
    }
    
    func generateResizedImageUrl(height: Int, width: Int, publicID: String)-> String{
        
        let resize = CLDTransformation().setWidth(width).setHeight(height).setFlags("progressive:steep").chain()
        return cloudinary.createUrl().setTransformation(resize).generate(publicID)!
        
    }
    
    func deleteImage(publicID: String){
        
        //  let cloudinaryAPI = cloudinary.createManagementApi()
        
        
        
    }
    
    func uploadImage<T>(call: CloudinaryCall<T>) -> Single<T>{
        
        return Single<T>.create { observer in
            
            let uploader = self.cloudinary.createUploader()
            
            
            let request = uploader.upload(data: call.imageData!, uploadPreset: call.uploadPreset!, params: nil)
            
            request.response({ (result, error) in
                
                if error == nil{
                    
                    
                    let json =  result!.resultJson
                    if let jsonData = try? JSONSerialization.data(withJSONObject: json, options:[]){
                        
                        if let value = ((try? call.decode(jsonData)) as T??){
                            
                            observer(.success(value!))
                        }
                    }
                }else{
                    
                    observer(.failure(error!))
                    
                }
            })
            
            return Disposables.create{
                
                request.cancel()
            }
            
        }
    }
    
    
    
    
    func downloadImage(call: CloudinaryCall<UIImage>) -> Single<UIImage>{
        
        return Single<UIImage>.create { observer in
            
            let downloader = self.cloudinary.createDownloader()
            
            
            let request = downloader.fetchImage(call.url!, completionHandler: { (image, error) in
                
                if error == nil{
                    
                    observer(.success(image!))
                    
                }else{
                    
                    observer(.failure(error!))
                }
                
            })
            return Disposables.create{
                
                request.cancel()
            }
            
        }
    }
    
}
