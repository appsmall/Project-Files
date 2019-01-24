//
//  ScavengerService.swift
//  Scavenger Hunt
//
//  Created by Rahul Chopra on 30/05/18.
//  Copyright © 2018 Rahul Chopra. All rights reserved.
//

import Foundation

class Service: BaseService {
    
    static let shared = ScavengerHuntService()
    
    static func sharedInstance() -> ScavengerHuntService {
        return shared
    }
    
    private override init() { }
    
    func sendRequestForQuestionPlay(dict: Dictionary<String, String>, delegate: GetResponseDataProtocol) {
        super.sendRequestWithObj(obj: dict, serviceURL: ServiceConstants.kGetQuestion, serviceType: ServiceConstants.ServiceType.kSTGetQuestion, requestType: ServiceConstants.RequestType.kRTGetQuestion, delegate: delegate)
    }
    
    func sendRequestForCongrats(dict: Dictionary<String, String>, delegate: GetResponseDataProtocol) {
        super.sendRequestWithObj(obj: dict, serviceURL: ServiceConstants.kOfferGeneration, serviceType: ServiceConstants.ServiceType.kSTOfferGeneration, requestType: ServiceConstants.RequestType.kRTOfferGeneration, delegate: delegate)
    }
    
    override func serviceResult(responseObject: Any?, success: Bool, delegate: GetResponseDataProtocol) {
        super.serviceResult(responseObject: responseObject, success: success, delegate: delegate)
        
        let response = super.getResponseWithSucess(responseObject: responseObject, success: success, delegate: delegate)
        
        delegate.didGetResponseFromServerWithObject(responseObject: response)
        
    }
    
}
