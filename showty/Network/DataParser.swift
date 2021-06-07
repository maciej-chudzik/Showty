//
//  DataParser.swift
//  showty
//
//  Copyright © 2020-2021 Maciej Chudzik. All rights reserved.
//

import Foundation

struct DataParser<T:Codable>{
    
    static func createModelFromJSONData(data: Data)->T?{
        
        let decoder = JSONDecoder()
        var model: T?
        
        do {
            model = try decoder.decode(T.self, from: data)
            return model
        }catch{
            
            print(error.localizedDescription)
            return nil
        }
        
    }
    
    static func createModelFromDictionary(dict: [String: Any?])->T?{
        
        let decoder = DictionaryDecoder()
        var model: T?
        
        do{
            model = try decoder.decode(T.self, from: dict as [String : Any])
            return model
            
            
        } catch let DecodingError.dataCorrupted(context) {
            print(context)
            return nil
        } catch let DecodingError.keyNotFound(key, context) {
            print("Key '\(key)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
            return nil
        } catch let DecodingError.valueNotFound(value, context) {
            print("Value '\(value)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
            return nil
        } catch let DecodingError.typeMismatch(type, context)  {
            print("Type '\(type)' mismatch:", context.debugDescription)
            print("codingPath:", context.codingPath)
            return nil
        } catch {
            print("error: ", error)
            return nil
        }
        
    }
    
}
