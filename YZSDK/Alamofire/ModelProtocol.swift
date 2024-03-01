//
//  ModelProtocol.swift
//  YZSDK
//
//  Created by lester on 2024/2/28.
//

import Foundation

public protocol ModelProtocol {
    func decodeModel(dict: [String : Any]) -> Self?
}

open class BaseModel: ModelProtocol {
    
    required public init() {
        
    }
    
    open func decodeModel(dict: [String : Any]) -> Self? {
        return self
    }
    
}
