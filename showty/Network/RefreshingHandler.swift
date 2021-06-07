//
//  RefreshingHandler.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import Foundation
import Alamofire

class RefreshingHandler: RequestInterceptor{
    
    private typealias RefreshCompletion = (_ succeeded: Bool, _ accessToken: String?, _ refreshToken: String?) -> Void
    
    private var session: Session
    private let lock = NSLock()
    private var baseURLString: String
    private var accessToken: String
    private var refreshToken: String
    private var isRefreshing = false
    private var requestsToRetry: [(RetryResult) -> Void] = []
    
    
    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.baseURLString = PlistReader.shared.getValue(nameOfFile: "Info", nameOfKey: "ShowtyRESTAPIUrl") as! String
        self.refreshToken = refreshToken
        
        var additionalHeaders = [AnyHashable : Any]()
        
        additionalHeaders["Authorization"] = "Bearer \(String(describing: refreshToken))"
        
        additionalHeaders["Content-Type"] = "application/json"
        
        let configuration = URLSessionConfiguration.af.default
        
        configuration.httpAdditionalHeaders = additionalHeaders
        
        self.session = Session(configuration: configuration)
        
    }
    
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void){
        
        
        if let urlString = urlRequest.url?.absoluteString, urlString.hasPrefix(baseURLString) {
            var urlRequest = urlRequest
            
            urlRequest.headers.add(.authorization(bearerToken: accessToken))
            completion(.success(urlRequest))
        }
        
    }
    
    
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void ){
        lock.lock() ; defer { lock.unlock() }
        
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 {
            
            
            requestsToRetry.append(completion)
            
            if !isRefreshing {
                refreshTokens { [weak self] succeeded, accessToken, refreshToken in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }
                    
                    if let accessToken = accessToken{
                        strongSelf.accessToken = accessToken
                        
                    }
                    
                    strongSelf.requestsToRetry.forEach { $0(.retry) }
                    strongSelf.requestsToRetry.removeAll()
                }
            }
        } else {
            completion(.doNotRetry)
        }
    }
    
    
    private func refreshTokens(completion: @escaping RefreshCompletion) {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        let urlString = "\(baseURLString)/refresh"
        
        
        session.request(urlString, method: .post, parameters: nil, encoding: JSONEncoding.default)
            .responseJSON { [weak self] response in
                
                guard let strongSelf = self else { return }
                
                if let json = response.value as? [String: Any], let accessToken = json["access_token"] as? String{
                    var tokens = Tokens()
                    tokens.access_token = accessToken
                    if tokens.saveTokenToKeyChain(token_type: "access_token"){
                        
                        completion(true, accessToken, nil)
                    }
                    
                    
                } else {
                    completion(false, nil, nil)

                    if response.response?.statusCode == 401 {
                        
                        if Tokens.deleteTokensFromKeyChain() {
                            
                            UserDefaults.standard.setNilValueForKey("host")
                            
                            let currentVC = UIHelper.getVisibleViewController(nil)
                            
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            
                            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                            
                            currentVC?.present(loginVC, animated: true, completion: nil)
                            
                        }
                        
                    }
                }
                
                strongSelf.isRefreshing = false
            }
    }
}
