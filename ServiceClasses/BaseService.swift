//
//  BaseService.swift
//  Scavenger Hunt
//
//  Created by Rahul Chopra on 30/05/18.
//  Copyright © 2018 Rahul Chopra. All rights reserved.
//

import Foundation
import Alamofire

protocol GetResponseDataProtocol {
    func didGetResponseFromServerWithObject(responseObject: Response)
}

class BaseService: NSObject {
    
    func sendRequestWithObj(obj: Dictionary<String,String>, serviceURL: String, serviceType: ServiceConstants.ServiceType, requestType: ServiceConstants.RequestType, delegate: GetResponseDataProtocol) {
        
        let urlString = ServiceConstants.kBaseURL + serviceURL
        let param: Parameters = obj
        let headers: [String: String] = [:]
        
        Alamofire.request(urlString, method: .post, parameters: param, encoding: URLEncoding.httpBody, headers: headers).responseJSON { (response) in
            
            switch response.result {
                case .success :
                    if let json = response.result.value {
                        self.serviceResult(responseObject: json, success: true, delegate: delegate)
                    }
                case .failure :
                    self.serviceResult(responseObject: nil, success: false, delegate: delegate)
            }
        }
        
    }
    
    func serviceResult(responseObject: Any?, success: Bool, delegate: GetResponseDataProtocol) {
        if success {
            print("API Success")
        }
        else {
            print("API Failed")
        }
    }
    
    func getResponseWithSucess(responseObject: Any?, success: Bool, delegate: GetResponseDataProtocol) -> Response {
        let response = Response()
        response.dataObject = responseObject as? Dictionary
        response.success = success
        return response
    }
    
}
