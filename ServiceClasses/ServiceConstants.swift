//
//  ServiceConstants.swift
//  Scavenger Hunt
//
//  Created by Rahul Chopra on 30/05/18.
//  Copyright © 2018 Rahul Chopra. All rights reserved.
//

import Foundation

struct ServiceConstants {
    
    //Devlopment
    static let kBaseURL = ""
    
    static let kGetQuestion = "/getQues"
    
    //MARK:- REQUEST PARAMETERS
    struct RequestParameter {
        static let kQui = "qui"
    }
    
    enum ServiceType {
        case kSTGetApi
    }
    
    enum RequestType {
        case kRTGetApi
    }
    
}
