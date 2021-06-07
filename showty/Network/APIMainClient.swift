//
//  APIMainClient.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift



final class APIMainClient {
    
    deinit{
        print("APIMainClient deinit")
    }
    
    lazy private var regularSession: Session? = {
        
        let configuration = URLSessionConfiguration.af.default
        
        let accessToken = Tokens.retrieveTokenFromKeyChain(token_type: "access_token")
        
        let refreshToken = Tokens.retrieveTokenFromKeyChain(token_type: "refresh_token")
        
        let handler = RefreshingHandler(accessToken:  accessToken!, refreshToken: refreshToken!)
        
        return Session(configuration: configuration, interceptor: handler)
        
        
    }()
    
    
    lazy private var refreshSession: Session? = {
        
        let configuration = URLSessionConfiguration.af.default
        
        let refreshToken = Tokens.retrieveTokenFromKeyChain(token_type: "refresh_token")
        
        var additionalHeaders = [String : Any]()
        
        additionalHeaders["Content-Type"] = "application/json"
        
        additionalHeaders["Authorization"] = "Bearer \(refreshToken!)"
        
        configuration.httpAdditionalHeaders = additionalHeaders
        
        return Session(configuration: configuration)
        
    }()
    
    lazy private var noTokensSession: Session? = {
        
        let configuration = URLSessionConfiguration.af.default
        
        return Session(configuration: configuration)
        
    }()
    
    
    private let baseURL = URL(string: PlistReader.shared.getValue(nameOfFile: "Info", nameOfKey: "ShowtyRESTAPIUrl") as! String)!
    private let queue = DispatchQueue(label: "label")
    
    
    
    private func url(path: String) -> URL {
        return baseURL.appendingPathComponent(path)
    }
    
    private func chooseSession(option: CallOption?) -> Session{
        
        switch option{
        
        case nil:
            
            return self.regularSession!
            
        case .onlyRefreshToken:
            
            return self.refreshSession!
            
        case .noTokens:
            
            return self.noTokensSession!

        }
        
    }
    
    
    func request<T>(_ apicall: APICall<T>) -> Single<T> {
        
        
        return Single<T>.create { observer in
            
           
            let request = self.chooseSession(option: apicall.option).request(self.url(path: apicall.endpoint),method: self.httpMethod(from: apicall.method),parameters: apicall.parameters, encoding: JSONEncoding.default)
            request
                .validate()
            
                .responseData(queue: self.queue) { response in
                    
                    let result = response.map(apicall.decode)
                    
                    if result.error == nil{
                        
                        observer(.success(result.value!))
                        
                    }else{
                        
                        let data = response.data
                        
                        if let serverError = try? JSONDecoder().decode(APIServerError.self, from: data!){
                            
                            observer(.failure(serverError))
                        }
                        
                        observer(.failure(result.error!))
                        
                    }
 
                }
            return Disposables.create{
                request.cancel()
            }
        }
    }
    
    func requestSearch<T: Codable>(_ apicall: APICall<T>) -> Observable<T> {
        
        
        return Observable<T>.create { [unowned self] observer in
            
            
            let request = self.regularSession!.request(self.url(path: apicall.endpoint),method: self.httpMethod(from: apicall.method),parameters: apicall.parameters, encoding: JSONEncoding.default)
            request
                .validate()
                
                .responseData(queue: self.queue) { response in
                    
                    let result = response.map(apicall.decode)
                    
                    if result.error == nil{
                        
                        observer.onNext(result.value!)
                        
                    }else{
                        let data = response.data
                        if let serverError = try? JSONDecoder().decode(APIServerError.self, from: data!){
                            
                            observer.onError(serverError)
                        }
                        observer.onError(result.error!)
                        
                    }
                    observer.onCompleted()
                    
                }
            
            return Disposables.create{
                request.cancel()
            }
        }
    }

    private func httpMethod(from method: Method) -> Alamofire.HTTPMethod {
        switch method {
        case .get: return .get
        case .post: return .post
        case .put: return .put
        case .patch: return .patch
        case .delete: return .delete
        }
    }
    
    
}

    

