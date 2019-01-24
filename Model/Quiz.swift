//
//  Quiz.swift
//  Scavenger Hunt
//
//  Created by Shashank Panwar on 5/10/18.
//  Copyright © 2018 Shashank Panwar. All rights reserved.
//

import Foundation
import CoreLocation

enum Status : Int{
    case inReview = 0
    case approved = 1
    case rejected = 2
    case suspended = 3
}

class Quiz{
    
    init() {
        //print("Quiz Object Created")
    }
    deinit {
        //print("Quiz Object Destroyed")
    }
    private var _id: String?
    private var _name: String?
    private var _imageUrl: String?
    private var _authorId: String?
    private var _address: String?
    private var _country: String?
    private var _state: String?
    private var _city: String?
    private var _place: String?
    private var _status = Status.inReview
    private var _quizPlayedCount = 0
    private var _location = CLLocationCoordinate2D()
    private var _timestamp : Int64?
    private var _rejectMessage: String?
    private var _rejectTimestamp : Int64?
    private var _approvedTimestamp : Int64?
    private var _userType = "user"
    
    var userType : String{
        get{
            return _userType
        }
    }
    
    var approvedTimeStamp : Int64{
        set{
            _approvedTimestamp = newValue
        }
        get{
            if _approvedTimestamp == nil{
                _approvedTimestamp = 0
            }
            return _approvedTimestamp!
        }
    }
    
    var rejectTimeStamp : Int64{
        set{
            _rejectTimestamp = newValue
        }
        get{
            if _rejectTimestamp == nil{
                _rejectTimestamp = 0
            }
            return _rejectTimestamp!
        }
    }
    
    var rejectMessage : String{
        set{
            _rejectMessage = newValue
        }
        get{
            if _rejectMessage == nil{
                _rejectMessage = ""
            }
            return _rejectMessage!
        }
    }
    
    var timeStamp : Int64{
        set{
            _timestamp = newValue
        }
        get{
            if _timestamp == nil{
                _timestamp = 0
            }
            return _timestamp!
        }
    }
    
    var location: CLLocationCoordinate2D{
        set{
            _location = newValue
        }
        get{
            return _location
        }
    }
    var quizPlayedCount: Int{
        set{
            _quizPlayedCount = newValue
        }
        get{
            return _quizPlayedCount
        }
    }
    var status : Status{
        set{
            _status = newValue
        }
        get{
            return _status
        }
    }
    
    var place : String{
        set{
            _place = newValue
        }
        get{
            if _place == nil{
                _place = emptyString
            }
            return _place!
        }
    }
    
    var city: String{
        set{
            _city = newValue
        }
        get{
            if _city == nil{
                _city = emptyString
            }
            return _city!
        }
    }
    
    var state : String{
        set{
            _state = newValue
        }
        get{
            if _state == nil{
                _state = emptyString
            }
            return _state!
        }
    }
    
    var country: String{
        set{
            _country = newValue
        }
        get{
            if _country == nil{
                _country = emptyString
            }
            return _country!
        }
    }
    
    var address: String{
        set{
            _address = newValue
        }
        get{
            if _address == nil{
                _address = emptyString
            }
            return _address!
        }
    }
    
    var authorId : String{
        set{
            _authorId = newValue
        }
        get{
            if _authorId == nil{
                _authorId = emptyString
            }
            return _authorId!
        }
    }
    
    var imageUrl: String{
        set{
            _imageUrl = newValue
        }
        get{
            if _imageUrl == nil{
                _imageUrl = emptyString
            }
            return _imageUrl!
        }
    }
    
    var name: String{
        set{
            _name = newValue
        }
        get{
            if _name == nil{
                _name  = emptyString
            }
            return _name!
        }
    }
    
    var id : String{
        set{
            _id = newValue
        }
        get{
            if _id == nil{
                _id = emptyString
            }
            return _id!
        }
    }
    
}
