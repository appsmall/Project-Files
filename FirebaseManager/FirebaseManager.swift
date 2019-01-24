//                  //
//  FirebaseManager.swift
//  Scavenger Hunt
//
//  Created by Shashank Panwar on 4/26/18.
//  Copyright © 2018 Shashank Panwar. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import CoreLocation

class FirebaseManager{
    private var databaseRef : DatabaseReference?
    private init(){
        databaseRef = Database.database().reference()
        databaseRef?.keepSynced(true)
        
    }
    static let sharedInstance = FirebaseManager()
    weak var delegate : StateListVC?
    
    //MARK:- USER AUTHENTICATION CHECK (ADMIN USER, BUSSINESS USER , NORMAL USER)
    func checkUserExistInUserTableOrNotBlocked(withUserId userId: String, completion: @escaping (Bool, String) -> ()){
        guard let ref = databaseRef else {
            completion(false,databaseInstance_unavailable)
            return
        }
        let childRef = ref.child(FbNode.kKeyUserNode).child(userId)
//        childRef.keepSynced(true)
        childRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                // User Exist in User List
                if let userInfo = snapshot.value as? [String: Any]{
                    if let userBlockStatus = userInfo[FbUserKey.kKeyBlockStatus] as? Int{
                        if userBlockStatus == 0{
                            completion(true, "User can success")
                        }else{
                            completion(false, "User is blocked by Admin")
                        }
                    }else{
                        completion(false, "Error \"is block\" field not available for this user")
                    }
                }
            }else{
                // User Not Exist in User List
                completion(false, "User not present in User Table")
            }
        }
    }
    
    func checkWhetherUserLogin(userId : String , completion: @escaping (Bool, String) -> ()){
        guard let ref = databaseRef else {
            return
        }
        let userRef = ref.child(FbNode.kKeyUserNode).queryOrdered(byChild: FbUserKey.kKeyUserId).queryEqual(toValue: userId)
//        userRef.keepSynced(true)
        userRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                completion(true, "Login Successfully")
            }else{
                let businessRef = ref.child(FbNode.kKeyBussinessUser).queryOrdered(byChild: "userId").queryEqual(toValue: userId)
//                businessRef.keepSynced(true)
                businessRef.observeSingleEvent(of: .value, with: { (snapShot) in
                    if snapShot.exists(){
                        completion(false, "Invalid Credential for user!")
                    }else{
                        let adminRef = ref.child("admin").queryOrdered(byChild: "firebaseId").queryEqual(toValue: userId)
//                        adminRef.keepSynced(true)
                        adminRef.observeSingleEvent(of: .value, with: { (snapShot) in
                            if snapShot.exists(){
                                completion(false, "Invalid Credential for user!")
                            }else{
                                completion(true, "Login Successfully")
                            }
                        })
                    }
                })
            }
        }
    }
    
    func handleBlockedUser(completion: @escaping (Bool, String?) -> ()){
        guard let ref = databaseRef else {
            return
        }
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let userRef = ref.child(FbNode.kKeyUserNode).child(user.uid)
        userRef.removeAllObservers()
//        userRef.keepSynced(true)
        userRef.observe(.childChanged) { (snapshot) in
            if snapshot.key == FbUserKey.kKeyBlockStatus{
                if let userBlockStatus = snapshot.value as? Int{
                    if userBlockStatus == 0{
                        //Not blocked User
                        completion(false, "Unblocked")
                    }else{
                        // Blocked User
                        completion(true, "Blocked")
                    }
                }
            }
        }
        
        userRef.observeSingleEvent(of: .value) { (snapshot) in
            if let userInfo = snapshot.value as? [String: Any]{
                if let userBlockStatus = userInfo[FbUserKey.kKeyBlockStatus] as? Int{
                    if userBlockStatus == 0{
                        //Not blocked User
                        completion(false, "Unblocked")
                    }else{
                        // Blocked User
                        completion(true, "Blocked")
                    }
                }
            }
        }
    }
    
    func removeObserverForUser(){
        guard let ref = databaseRef else {
            return
        }
        guard let user = Auth.auth().currentUser else {
            print("User not found")
            return
        }
        let userRef = ref.child(FbNode.kKeyUserNode).child(user.uid)
//        userRef.keepSynced(true)
        userRef.removeAllObservers()
    }
    
    //MARK:- STORE AND UPDATE USER DATA
    func storeUserIntoFirebase(withUserId userId: String, userInfo: [String: Any], completion: @escaping (Bool,String?) -> ()){
        guard let ref = databaseRef else {
            completion(false,databaseInstance_unavailable)
            return
        }
        print("Completion : \(completion)")
        let userDict = userInfop(
        let childRef = ref.child(FbNode.kKeyUserNode).child(userId)
//        childRef.keepSynced(true)
        childRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                // Data present for this userId so updated the required field

                if let userInfo = snapshot.value as? [String: Any]{
                    if let userBlockStatus = userInfo[FbUserKey.kKeyBlockStatus] as? Int{
                        if userBlockStatus == 0{
                            //User not blocked by admin
                            Utility.storeValueInUserDefaultFromFirebaseDatabase(userDict: userInfo)
                            let userReference = ref.child(FbNode.kKeyUserNode).child(userId)
                            userReference.updateChildValues(userDict) { (error, ref) in
                                if let err = error{
                                    completion(false,err.localizedDescription)
                                    return
                                }
                                //need to set updated tokens to User as well as UserDefault at the time of sign In
                                Utility.updateUserData(userDict: userDict)
                                Utility.setUserValuesInUserDefault(user: User.shared())
                                completion(true,"User can success")
                            }
                        }else{
                            //User blocked by admin
                            completion(false, "User is blocked by Admin")
                        }
                    }else{
                        completion(false, "Error \"is block\" field not available for this user")
                    }
                }
            }else{
                // Data not present for this userId so created new user node
                Utility.storeValueInUserDefaultFromFirebaseDatabase(userDict: userDict)
                guard var updateDict = Utility.getUserInfoFromUserDefaults() as? [String: Any] else{
                    return
                }
                updateDict[FbUserKey.kKeyTimestamp] = ServerValue.timestamp()
                let userReference = ref.child(FbNode.kKeyUserNode).child(userId)
                userReference.updateChildValues(updateDict) { (error, ref) in
                    if let err = error{
                        completion(false,err.localizedDescription)
                        return
                    }
                    completion(true,nil)
                }
            }
        }
    }
    
    func getQuizAuthorFromUserId(userId: String, completion: @escaping (Bool, QuizAuthor?) -> Void){
        guard let ref = databaseRef else {
            completion(false,nil)
            return
        }
        let childRef = ref.child(FbNode.kKeyUserNode).child(userId)
//        childRef.keepSynced(true)
        childRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                if let userInfo = snapshot.value as? [String: Any]{
                    let author = self.getAuthorInfo(autherDict: userInfo)
                    completion(true, author)
                }
            }
        }
        let childsRef = ref.child(FbNode.kKeyBussinessUser).child(userId)
//        childsRef.keepSynced(true)
        childsRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                if let userInfo = snapshot.value as? [String: Any]{
                    let author = self.getAuthorInfo(autherDict: userInfo)
                    completion(true, author)
                }
            }
        }
    }
    
    private func getAuthorInfo(autherDict : [String: Any]) -> QuizAuthor{
        let authorInfo = QuizAuthor()
        if let deviceType = autherDict[FbUserKey.kKeyDeviceType] as? String{
            authorInfo.deviceType = deviceType
        }
        if let dob = autherDict[FbUserKey.kKeyDob] as? String{
            authorInfo.dob = dob
        }
        if let email = autherDict[FbUserKey.KkeyEmail] as? String{
            authorInfo.email = email
        }
        if let name = autherDict[FbUserKey.kKeyName] as? String{
            authorInfo.name = name
        }
        if let notificationToken = autherDict[FbUserKey.kKeyNotificationToken] as? String{
            authorInfo.notificationToken = notificationToken
        }
        if let phoneNo = autherDict[FbUserKey.kKeyPhoneNo] as? String{
            authorInfo.phoneNo = phoneNo
        }
        if let profileImage = autherDict[FbUserKey.kKeyProfileImage] as? String{
            authorInfo.profileImage = profileImage
        }
        if let userId = autherDict[FbUserKey.kKeyUserId] as? String{
            authorInfo.userId = userId
        }
        if let deviceToken = autherDict[FbUserKey.kKeyDeviceToken] as? String{
            authorInfo.deviceToken = deviceToken
        }
        if let blockStatus = autherDict[FbUserKey.kKeyBlockStatus] as? Int{
            authorInfo.blockStatus = blockStatus
        }
        if let instaLink = autherDict[FbUserKey.kKeyInstaLink] as? String{
            authorInfo.instaLink = instaLink
        }
        if let instaImageUrl = autherDict[FbUserKey.kKeyInstaImageUrl] as? String{
            authorInfo.instaImageUrl = instaImageUrl
        }
        return authorInfo
    }
    
    //MARK:- Store Quiz Data
    func storeQuizIntoFirebase(quizInfo : Quiz, completion : @escaping (Bool, String?) -> ()){
        guard let ref = databaseRef else {
            completion(false,databaseInstance_unavailable)
            return
        }
        
        let quizNodeKey = ref.child(FbNode.kKeyQuizNode).childByAutoId().key
        quizInfo.id = quizNodeKey
        let quizData = prepareQuizForStoreInFirebase(quiz: quizInfo)
        let quizNodeReference = ref.child(FbNode.kKeyQuizNode).child(quizNodeKey)
        quizNodeReference.updateChildValues(quizData) { (error, ref) in
            if let err = error{
                completion(false,err.localizedDescription)
            }
            completion(true, quizNodeKey)
        }
    }
    
    func prepareQuizForStoreInFirebase(quiz: Quiz) -> [String: Any]{
        var quizInfo = [String: Any]()
        quizInfo[FbQuizKey.kKeyAddress] = quiz.address
        quizInfo[FbQuizKey.kKeyAuthorId] = quiz.authorId
        quizInfo[FbQuizKey.kKeyCity] = quiz.city
        quizInfo[FbQuizKey.kKeyCountry] = quiz.country
        quizInfo[FbQuizKey.kKeyId] = quiz.id
        quizInfo[FbQuizKey.kKeyImageUrl] = quiz.imageUrl
        quizInfo[FbQuizKey.kKeyName] = quiz.name
        quizInfo[FbQuizKey.kKeyPlace] = quiz.place
        quizInfo[FbQuizKey.kKeyQuizPlayedCount] = quiz.quizPlayedCount
        quizInfo[FbQuizKey.kKeyState] = quiz.state
        quizInfo[FbQuizKey.kKeyStatus] = quiz.status.rawValue
        quizInfo[FbQuizKey.kKeyTimestamp] = ServerValue.timestamp()
        quizInfo[FbQuizKey.kKeyRejectMessage] = quiz.rejectMessage
        quizInfo[FbQuizKey.kKeyRejectTimestampt] = quiz.rejectTimeStamp
        quizInfo[FbQuizKey.kKeyApproveTimestamp] = quiz.approvedTimeStamp
        quizInfo[FbQuizKey.kKeyUserType] = quiz.userType
        return quizInfo
    }
    
    //MARK:- STORE QUIZ LOCATION
    func storeLocationForQuiz(coordinate : CLLocationCoordinate2D, quizId: String, completion: @escaping (Bool, String?) -> ()){
        guard let ref = databaseRef else {
            completion(false,databaseInstance_unavailable)
            return
        }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let quizLocationRef = ref.child(FbNode.kKeyQuizLocation)
        let geoFireRef = GeoFire(firebaseRef: quizLocationRef)
        geoFireRef.setLocation(location, forKey: quizId)
        completion(true, nil)
    }
    
    
    //MARK:- STORE QUESTION DATA
    func storeQuestionForQuizIntoFirebase(question: Question, quizId : String, completion: @escaping (Bool, String?) -> ()){
        guard let ref = databaseRef else {
            completion(false,databaseInstance_unavailable)
            return
        }
        let questionNodeKey = ref.child(FbNode.kKeyQuestionNode).child(quizId).childByAutoId().key
        let questionNodeRef = ref.child(FbNode.kKeyQuestionNode).child(quizId).child(questionNodeKey)
        let questioninfo = prepareQuestionForStoreInDatabase(question: question)
        questionNodeRef.updateChildValues(questioninfo) { (error, ref) in
            if let err = error {
                //TODO:- ERROR WHILE STORING QUESTION DATA IN FIREBASE DATABASE
                print("Error: \(err.localizedDescription)")
                completion(false, err.localizedDescription)
                return
            }
            completion(true, nil)
        }
    }
    
    func prepareQuestionForStoreInDatabase(question: Question) -> [String: Any]{
        var questionDict = [String: Any]()
        questionDict[FbQuestionKey.kKeyCorrectOption] = question.correctOption.rawValue
        if question.type == .image{
            questionDict[FbQuestionKey.kKeyImage] = question.imageUrl
        }else{
            questionDict[FbQuestionKey.kKeyImage] = emptyString
        }
        questionDict[FbQuestionKey.kKeyOptionA] = question.optionA
        questionDict[FbQuestionKey.kKeyOptionB] = question.optionB
        questionDict[FbQuestionKey.kKeyOptionC] = question.optionC
        questionDict[FbQuestionKey.kKeyOptionD] = question.optionD
        questionDict[FbQuestionKey.kKeyQuestion] = question.question
        questionDict[FbQuestionKey.kKeyType] = question.type.rawValue
        return questionDict
    }
    
    func getQuestionFromFirebase(questionInfo : [String: Any]) -> Question{
        let question = Question()
        if let questionType = questionInfo[FbQuestionKey.kKeyType] as? String{
            if let type = QuestionType(rawValue: questionType){
                question.type = type
            }
        }
        if let correctOption = questionInfo[FbQuestionKey.kKeyCorrectOption] as? String{
            if let option = CorrectOption(rawValue: correctOption){
                question.correctOption = option
            }
        }
        if let image = questionInfo[FbQuestionKey.kKeyImage] as? String{
            question.imageUrl = image
        }
        if let questionData = questionInfo[FbQuestionKey.kKeyQuestion] as? String{
            question.question = questionData
        }
        if let optionA = questionInfo[FbQuestionKey.kKeyOptionA] as? String{
            question.optionA = optionA
        }
        if let optionB = questionInfo[FbQuestionKey.kKeyOptionB] as? String{
            question.optionB = optionB
        }
        if let optionC = questionInfo[FbQuestionKey.kKeyOptionC] as? String{
            question.optionC = optionC
        }
        if let optionD = questionInfo[FbQuestionKey.kKeyOptionD] as? String{
            question.optionD = optionD
        }
        print(question)
        return question
    }
    
    func fetchQuestions(fromQuiz quizId: String, completion: @escaping (Bool, [Question]?) -> ()){
        guard let ref = databaseRef else {
            completion(false,nil)
            return
        }
        var allQuestions = [Question]()
        let quizRef = ref.child(FbNode.kKeyQuestionNode).child(quizId)
//        quizRef.keepSynced(true)
        quizRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                if let questions = snapshot.value as? [String: Any]{
                    for question in questions{
                        if let questionData = question.value as? [String: Any]{
                            let fetchedQuestion = self.getQuestionFromFirebase(questionInfo: questionData)
                            allQuestions.append(fetchedQuestion)
                        }
                    }
                    completion(true,allQuestions)
                }
            }else{
                completion(false, nil)
            }
        }
    }
    
    func deleteQuestions(fromQuiz quizId : String, completion: @escaping (Bool, String?) -> ()){
        guard let ref = databaseRef else {
            completion(false,nil)
            return
        }
        let quizRef = ref.child(FbNode.kKeyQuestionNode).child(quizId)
        quizRef.removeValue()
        completion(true, "Question Deleted")
    }
    
    //MARK: Password Reset
    func forgotPassword(email: String, completion: @escaping (Bool,String?) -> Void ){
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            if let err = error{
                completion(false, err.localizedDescription)
                return
            }
            completion(true,nil)
        }
    }
    
    func getInitialRadius(ForLocation location: CLLocationCoordinate2D, radius: Double, completed: @escaping (Bool, Double) -> ()){
        var quizzes = [Quiz]()
        guard let ref = databaseRef else {
            return
        }
        let quizLocationRef = ref.child(FbNode.kKeyQuizLocation)
        let geoFire = GeoFire(firebaseRef: quizLocationRef)
        let center = CLLocation(latitude: location.latitude, longitude: location.longitude)
        //This timer is used to remove the activity indicator if and only if there is no quiz found untill 3 second passed.
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 8, target: self, selector: #selector(self.handleEmptyQuizList(sender:)), userInfo: (location, radius, completed), repeats: false)
        let radiusInKm = Utility.changeMilesToKm(miles: radius)
        let circleQuery = geoFire.query(at: center, withRadius: radiusInKm)
        geoFire.firebaseRef.removeAllObservers()
//        geoFire.firebaseRef.keepSynced(true)
        _ = circleQuery.observe(.keyEntered, with: { (quizId, quizLocation) in
            let messageRef = ref.child(FbNode.kKeyQuizNode).child(quizId)
//            messageRef.keepSynced(true)
            messageRef.observeSingleEvent(of: .value, with: { (snapShot) in
                if let dict = snapShot.value as? [String: Any]{
                    let quiz = self.getQuizInformationFromFirebase(dict: dict)
                    quiz.location = quizLocation.coordinate
                    if quiz.status == .approved{
                        quizzes.append(quiz)
                        self.timer?.invalidate()
                        self.timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.handleSelectedRadius(sender:)), userInfo: (location, radius, completed), repeats: false)
                    }
                }
            }, withCancel: nil)
        })
    }
    
    @objc func handleSelectedRadius(sender: Timer){
        print("RADIUS FETCHING PROCESS...")
        if let searchInfo = sender.userInfo as? (CLLocationCoordinate2D,Double,(Bool, Double) -> ()){
            if let radiusIndex = defaultRadiusIncrease.index(of: searchInfo.1){
                let selectedRadius = defaultRadiusIncrease[radiusIndex]
                searchInfo.2(true, selectedRadius)
            }
        }
    }
    
    @objc func handleEmptyQuizList(sender: Timer){
        if let searchInfo = sender.userInfo as? (CLLocationCoordinate2D,Double,(Bool, Double) -> ()){
            if let radiusIndex = defaultRadiusIncrease.index(of: searchInfo.1){
                print("Current Radius : \(searchInfo.1)")
                print("Current Index : \(radiusIndex)")
                if radiusIndex < defaultRadiusIncrease.count - 1{
                    let newRadius = defaultRadiusIncrease[radiusIndex + 1]
                    print("Increased Radius : \(newRadius)")
                    self.getInitialRadius(ForLocation: searchInfo.0, radius: newRadius, completed: searchInfo.2)
                }else{
                    ActivityIndicator.shared().hide()
                    searchInfo.2(true, 3000.0)
                }
            }
        }
    }
    
    //MARK: Fetch Quiz based on radius
    func getQuizData(ForLocation location: CLLocationCoordinate2D, radius: Double, completed: @escaping (Bool, [Quiz]) -> ()){
        
        var quizzes = [Quiz]()
        guard let ref = databaseRef else {
            return
        }
        let quizLocationRef = ref.child(FbNode.kKeyQuizLocation)
        let geoFire = GeoFire(firebaseRef: quizLocationRef)
        let center = CLLocation(latitude: location.latitude, longitude: location.longitude)
        //This timer is used to remove the activity indicator if and only if there is no quiz found untill 3 second passed.
        self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.handleReloadTable(sender:)), userInfo: ["completed": completed, "Quizzes": quizzes, "radius":radius, "location": location], repeats: false)
        let radiusInKm = Utility.changeMilesToKm(miles: radius)
        let circleQuery = geoFire.query(at: center, withRadius: radiusInKm)
        geoFire.firebaseRef.removeAllObservers()
        //geoFire.firebaseRef.keepSynced(true)
        _ = circleQuery.observe(.keyEntered, with: { (quizId, location) in
            let messageRef = ref.child(FbNode.kKeyQuizNode).child(quizId)
            messageRef.removeAllObservers()
            messageRef.observe(.childChanged, with: {[unowned self] (snapshot) in
                if snapshot.key == FbQuizKey.kKeyStatus || snapshot.key == FbQuizKey.kKeyQuizPlayedCount{
                    self.delegate?.updateQuizData()
                }
            })
            messageRef.observeSingleEvent(of: .value, with: { (snapShot) in
                if let dict = snapShot.value as? [String: Any]{
                    let quiz = self.getQuizInformationFromFirebase(dict: dict)
                    quiz.location = location.coordinate
                    print("Quiz Location : \(location)")
                    if quiz.status == .approved{
                        quizzes.append(quiz)
                    }
                }
                quizzes = quizzes.sorted(by: { (quiz1, quiz2) -> Bool in
                    return quiz1.timeStamp > quiz2.timeStamp
                })
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.handleReloadTable(sender:)), userInfo: ["completed": completed, "Quizzes": quizzes, "radius":radius, "location": location], repeats: false)
            }, withCancel: nil)
        })
    }
    
    var timer : Timer?
    @objc func handleReloadTable(sender: Timer){
        print("Handle Reload Table")
        guard let ref = databaseRef else {
            return
        }
        let quizLocationRef = ref.child(FbNode.kKeyQuizLocation)
        let geoFire = GeoFire(firebaseRef: quizLocationRef)
         geoFire.firebaseRef.removeAllObservers()
//        geoFire.firebaseRef.keepSynced(true)
        if let dict = sender.userInfo as? [String: Any]{
            guard let quizzes = dict["Quizzes"] as? [Quiz] else{
                ActivityIndicator.shared().hide()
                return
            }
            guard let completed = dict["completed"] as? (Bool,[Quiz]) -> () else{
                ActivityIndicator.shared().hide()
                return
            }
            if quizzes.count == 0{
                ActivityIndicator.shared().hide()
                 completed(true, [Quiz]())
            }else{
                ActivityIndicator.shared().hide()
                completed(true, quizzes)
            }
        }
    }
    
    private func getQuizInformationFromFirebase(dict: [String: Any] ) -> Quiz{
        let quiz = Quiz()
        if let address = dict[FbQuizKey.kKeyAddress] as? String{
            quiz.address = address
        }
        if let autherId = dict[FbQuizKey.kKeyAuthorId] as? String{
            quiz.authorId = autherId
        }
        if let city = dict[FbQuizKey.kKeyCity] as? String{
            quiz.city = city
        }
        if let country = dict[FbQuizKey.kKeyCountry] as? String{
            quiz.country = country
        }
        if let quizId = dict[FbQuizKey.kKeyId] as? String{
            quiz.id = quizId
        }
        if let imageUrl = dict[FbQuizKey.kKeyImageUrl] as? String{
            quiz.imageUrl = imageUrl
        }
        if let name = dict[FbQuizKey.kKeyName] as? String{
            quiz.name = name
        }
        if let place = dict[FbQuizKey.kKeyPlace] as? String{
            quiz.place = place
        }
        if let numberOfTimesQuizPlayed = dict[FbQuizKey.kKeyQuizPlayedCount] as? Int{
            quiz.quizPlayedCount = numberOfTimesQuizPlayed
        }
        if let state = dict[FbQuizKey.kKeyState] as? String{
            quiz.state = state
        }
        if let status = dict[FbQuizKey.kKeyStatus] as? Int{
            if let validStatus = Status(rawValue: status){
                quiz.status = validStatus
            }
        }
        if let timeStamp = dict[FbQuizKey.kKeyTimestamp] as? NSNumber{
               quiz.timeStamp = timeStamp.int64Value
        }
        if let rejectMessage = dict[FbQuizKey.kKeyRejectMessage] as? String{
            quiz.rejectMessage = rejectMessage
        }
        if let rejectTimestamp = dict[FbQuizKey.kKeyRejectTimestampt] as? NSNumber{
            quiz.rejectTimeStamp = rejectTimestamp.int64Value
        }
        if let approvedTimestamp = dict[FbQuizKey.kKeyApproveTimestamp] as? NSNumber{
            quiz.approvedTimeStamp = approvedTimestamp.int64Value
        }
        return quiz
    }
    
    func getUserQuiz(withUserID uid: String, completion: @escaping (Bool,[Quiz]?) -> ()) {
        var quizzes = [Quiz]()
        guard let ref = databaseRef else {
            completion(false, nil)
            return
        }
        let quizRef = ref.child(FbNode.kKeyQuizNode)
//        quizRef.keepSynced(true)
        quizRef.observe(.value) { (snapshot) in
            if let allQuizzes = snapshot.value as? [String:Any] {
                for quizInfo in allQuizzes{
                    if let quizData = quizInfo.value as? [String: Any]{
                        if let authorId = quizData["authorId"] as? String{
                            if authorId == uid{
                                let quiz = self.getQuizInformationFromFirebase(dict: quizData)
                                quizzes.append(quiz)
                            }else{
                                // User Id not matched with any quiz.
                            }
                        }
                    }
                }
                completion(true, quizzes)
                quizzes.removeAll()
            }
            else {
                completion(false, nil)
            }
        }
    }
    
    func updateQuizStatus(quizId: String){
        var statusUpdate = [String: Any]()
        guard let ref = databaseRef else {
            return
        }
        statusUpdate[FbQuizKey.kKeyStatus] = Status.inReview.rawValue
        ref.child(FbNode.kKeyQuizNode).child(quizId).updateChildValues(statusUpdate)
    }
    
    private func getQuizHistoryInformationFromFirebase(dict: [String:Any]) -> QuizHistory {
        let history = QuizHistory()
        if let quizId = dict[FbQuizHistoryKey.kKeyQuizId] as? String {
            history.quizId = quizId
        }
        if let userId = dict[FbQuizHistoryKey.kKeyUserId] as? String {
            history.userId = userId
        }
        if let totalQuestion = dict[FbQuizHistoryKey.kKeyTotalQuestion] as? Int {
            history.totalQuestion = totalQuestion
        }
        if let correctAnswer = dict[FbQuizHistoryKey.kKeyCorrectAnswer] as? Int {
            history.correctAnswer = correctAnswer
        }
        if let wrongAnswer = dict[FbQuizHistoryKey.kKeyWrongAnswer] as? Int {
            history.wrongAnswer = wrongAnswer
        }
        if let timeStamp = dict[FbQuizHistoryKey.kKeyTimestamp] as? NSNumber {
            history.timeStamp = timeStamp.int64Value
        }
        return history
    }
    
    
    private func getOfferInformationFromFirebase(valueDict: [String: Any]) -> Offer {
        let offer = Offer()
        
        if let businessName = valueDict[FbOffersKey.kKeyBusinessName] as? String {
            offer.businessName = businessName
        }
        if let desc = valueDict[FbOffersKey.kKeyDesc] as? String {
            offer.description = desc
        }
        if let id = valueDict[FbOffersKey.kKeyId] as? String {
            offer.id = id
        }
        if let offerEligibility = valueDict[FbOffersKey.kKeyOfferEligibility] as? Int {
            offer.offerEligibility = offerEligibility
        }
        if let offerTitle = valueDict[FbOffersKey.kKeyOfferTitle] as? String {
            offer.offerTitle = offerTitle
        }
        if let offerCode = valueDict[FbOffersKey.kKeyOfferCode] as? String {
            offer.offerCode = offerCode
        }
        if let quizId = valueDict[FbOffersKey.kKeyQuizId] as? String {
            offer.quizId = quizId
        }
        if let sponserId = valueDict[FbOffersKey.kKeySponserId] as? String {
            offer.sponsorId = sponserId
        }
        if let status = valueDict[FbOffersKey.kKeyStatus] as? Int {
            offer.status = status
        }
        if let validFrom = valueDict[FbOffersKey.kKeyValidFrom] as? NSNumber {
            offer.validFrom = validFrom.int64Value
        }
        if let validTo = valueDict[FbOffersKey.kKeyValidTo] as? NSNumber {
            offer.validTo = validTo.int64Value
        }
        if let offerType = valueDict[FbOffersKey.kKeyOfferType] as? String {
            if let type = OfferType(rawValue: offerType) {
                offer.offerType = type
            }
        }
        if let minQuesAttempt = valueDict[FbOffersKey.kKeyMinQuesAttempt] as? Int {
            offer.minQuesAttempt = minQuesAttempt
        }
        
        return offer
    }
    
    
    func getQuizHistory(withUserId uid: String, completion: @escaping (Bool, Int , QuizHistory?, Quiz?, [Offer]?) -> ()) {
        guard let ref = databaseRef else {
            completion(false, 0,nil, nil, nil)
            return
        }
        let quizHistoryRef = ref.child(FbNode.kKeyQuizHistory).child(uid).queryOrdered(byChild: FbQuizHistoryKey.kKeyTimestamp)
        quizHistoryRef.removeAllObservers()
//        quizHistoryRef.keepSynced(true)
        quizHistoryRef.observe(.value) { (snapshot) in
            if snapshot.exists(){
                if let quizData = snapshot.value as? [String: Any] {
                    let numberOfQuizInHistory = quizData.count
                    for eachQuiz in quizData {
                        if let quizHistoryDict = eachQuiz.value as? [String:Any] {
                            if let quizId = quizHistoryDict["quizId"] as? String {
                                let quizHistory = self.getQuizHistoryInformationFromFirebase(dict: quizHistoryDict)
                                self.getQuizFromHistory(withQuizId: quizId, quizHistory: quizHistory, completion: { (success, historyData, quizData, offerData)  in
                                    if success {
                                        completion(true,numberOfQuizInHistory ,historyData, quizData, offerData)
                                    }else{
                                        completion(false, 0, nil, nil, nil)
                                    }
                                })
                            }
                        }
                    }
                }
            }else{
                completion(false, 0 ,nil, nil, nil)
            }
        }
        
    }
    
    func getQuizFromHistory(withQuizId qid: String, quizHistory: QuizHistory, completion: @escaping (Bool, QuizHistory?, Quiz?, [Offer]?) -> ()) {
        guard let ref = databaseRef else {
            completion(false, nil, nil , nil)
            return
        }
        let quizRef = ref.child(FbNode.kKeyQuizNode)
//        quizRef.keepSynced(true)
        quizRef.observe(.value) { (snapshot) in
            if snapshot.exists(){
                if let allQuizzes = snapshot.value as? [String:Any] {
                    var quizCount = 0
                    for eachQuiz in allQuizzes {
                        quizCount += 1
                        let quizId = eachQuiz.key
                        if quizId == qid {
                            if let quizDict = eachQuiz.value as? [String: Any] {
                                guard let user = Auth.auth().currentUser else {
                                    print("User not found")
                                    return
                                }
                                let quiz = self.getQuizInformationFromFirebase(dict: quizDict)
                                self.getOfferFromQuiz(withUserId: user.uid, withQuizId: quizId, quiz: quiz, completion: { (success, quiz ,offerData) in
                                    if success {
                                        completion(true, quizHistory, quiz, offerData)
                                    }
                                })
                            }
                            else {
                                completion(false, nil, nil , nil)
                            }
                            break
                        }else{
                            // Particular quiz is not current quiz
                        }
                        if quizCount == allQuizzes.count {
                            //No Quiz Found in the quiz list
                            completion(false, nil, nil, nil)
                        }
                    }
                }
            }else{
                // No Quiz Data Found in quizzes table
                completion(false, nil, nil, nil)
            }
        }
    }
    
    //MARK:- Get Offers from Selected Quiz for a specific user
    func getOfferFromQuiz(withUserId uid: String, withQuizId qid: String, quiz: Quiz, completion: @escaping(Bool, Quiz?, [Offer]?) -> ()) {
        var offers = [Offer]()
        guard let ref = databaseRef else {
            completion(false,nil,nil)
            return
        }
        let offerRef = ref.child(FbNode.kKeyLockedOffer).child(uid).child(qid)
//        offerRef.keepSynced(true)
        offerRef.observeSingleEvent(of: .value) { (snapshot) in
            if let allOffersDict = snapshot.value as? [String: Any]{
                for eachOffer in  allOffersDict{
                    if let offerDict = eachOffer.value as? [String: Any]{
                        offers.append(self.getOfferInformationFromFirebase(valueDict: offerDict))
                    }
                }
                completion(true,quiz ,offers)
            }else{
                //No Offer found for this user Id & Quiz Id
                completion(true, quiz, nil)
            }
        }
    }
    
    func getSponsorImageUrl(sponserId: String, completion: @escaping(Bool, String?) -> ()){
        guard let ref = databaseRef else{
            completion(false, nil)
            return
        }
        let childRef = ref.child(FbNode.kKeyBussinessUser).child(sponserId)
//        childRef.keepSynced(true)
        childRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                if let businessUserInfoDict = snapshot.value as? [String: Any]{
                    if let instaImage = businessUserInfoDict[FbBusinessUserKey.kKeyInstagramImageUrl] as? String{
                        if instaImage != emptyString{
                            completion(true, instaImage)
                        }else{
                            if let imageUrl = businessUserInfoDict[FbBusinessUserKey.kKeyImageUrl] as? String{
                                completion(true, imageUrl)
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    func checkIfQuizAlreadyPlayed(quizId: String, completion: @escaping (Bool, String?) -> ()){
        guard let ref = databaseRef else{
            completion(false, nil)
            return
        }
        guard let currentUser = Auth.auth().currentUser else{
            return
        }
        let historyRef = ref.child(FbNode.kKeyQuizHistory).child(currentUser.uid)
//        historyRef.keepSynced(true)
        historyRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                //User exist in history
                let historySaveRef = historyRef.child(quizId)
//                historySaveRef.keepSynced(true)
                historySaveRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(){
                        //Quiz Already Played
                        completion(true, quizId)
                    }else{
                        //Quiz not played yet
                        completion(false, quizId)
                    }
                })
            }else{
                // User node in history not exist i.e. Quiz not played yet
                completion(false, quizId)
            }
        }
    }
    
    //MARK:- STORE HISTORY IN FIREBASE DATABASE
    func checkIfQuizNotAlreadyPlayed(quizId: String, historyInfo : QuizHistory, completion :@escaping (Bool, String) -> ()){
        guard let ref = databaseRef else{
            completion(false, databaseInstance_unavailable)
            return
        }
        guard let currentUser = Auth.auth().currentUser else{
            return
        }
        let historyRef = ref.child(FbNode.kKeyQuizHistory).child(currentUser.uid)
//        historyRef.keepSynced(true)
        historyRef.observeSingleEvent(of: .value) { (snapshot) in
            let historyData = self.prepareHistoryForStoreInFirebase(history: historyInfo)
            let historySaveRef = historyRef.child(quizId)
            historySaveRef.updateChildValues(historyData, withCompletionBlock: { (error, ref) in
                if let err = error{
                    print(err.localizedDescription)
                    return
                }
                completion(true, "Not Played Yet")
                //Successfully Saved
            })
        }
    }
    
    func prepareHistoryForStoreInFirebase(history: QuizHistory) -> [String: Any] {
        var historyDict = [String: Any]()
        historyDict[FbQuizHistoryKey.kKeyCorrectAnswer] = history.correctAnswer
        historyDict[FbQuizHistoryKey.kKeyQuizId] = history.quizId
        historyDict[FbQuizHistoryKey.kKeyTimestamp] = ServerValue.timestamp()
        historyDict[FbQuizHistoryKey.kKeyTotalQuestion] = history.totalQuestion
        historyDict[FbQuizHistoryKey.kKeyUserId] = history.userId
        historyDict[FbQuizHistoryKey.kKeyWrongAnswer] = history.wrongAnswer
        return historyDict
    }
    
    
    func updateScoreInFirebase(quizId : String, correctAnswer: Int, WrongAnswer: Int, completion: @escaping (Bool, String) -> ()){
        guard let ref = databaseRef else{
            //ERROR WHILE STORING HISTORY DATA IN FIREBASE DATABASE
            completion(false, databaseInstance_unavailable)
            return
        }
        guard let currentUser = Auth.auth().currentUser else{
            //Current User not available
            return
        }
        let childRef = ref.child(FbNode.kKeyQuizHistory).child(currentUser.uid).child(quizId)
//        childRef.keepSynced(true)
        childRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                let historyRef = ref.child(FbNode.kKeyQuizHistory).child(currentUser.uid).child(quizId)
                let uploadableContent = [FbQuizHistoryKey.kKeyCorrectAnswer: correctAnswer,
                                         FbQuizHistoryKey.kKeyWrongAnswer: WrongAnswer]
                historyRef.updateChildValues(uploadableContent, withCompletionBlock: { (error, ref) in
                    if let _ = error{
                        completion(false, "Error While Updating Game Data")
                        return
                    }
                    completion(true, "Game Data Successfully updated")
                })
                historyRef.updateChildValues(uploadableContent)
            }else{
                //Quiz Not Exist in database
                completion(false, "Quiz Not Exist in firebase database")
            }
        }
    }
    
    func updatePlayedCount(ofQuiz quizId: String, completion: @escaping (Bool,String) -> ()){
        guard let ref = databaseRef else{
            //ERROR WHILE STORING HISTORY DATA IN FIREBASE DATABASE
            completion(false, databaseInstance_unavailable)
            return
        }
        let quizRef = ref.child(FbNode.kKeyQuizNode).child(quizId)
//        quizRef.keepSynced(true)
        quizRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                if let quizInfo = snapshot.value as? [String: Any]{
                    if var playedCount = quizInfo[FbQuizKey.kKeyQuizPlayedCount] as? Int{
                        playedCount += 1
                        let playedCountUpdate = [FbQuizKey.kKeyQuizPlayedCount : playedCount]
                        quizRef.updateChildValues(playedCountUpdate)
                        completion(true, "")
                    }
                }
            }else{
                completion(false, "Quiz Not Found")
            }
        }
    }
    
    func getOffersFromFirebase(quizId: String, completion: @escaping (Bool, [Offer]?) -> ()) {
        var offersData = [Offer]()
        guard let ref = databaseRef else {
            completion(false, nil)
            return
        }
        let offersRef = ref.child("offers")
//        offersRef.keepSynced(true)
        offersRef.observeSingleEvent(of: .value) { (snapshot) in
            var isOfferAvailable = false
            if let allOffers = snapshot.value as? [String: Any] {
                print(allOffers.count)
                for eachOffer in allOffers {
                    if let offerData = eachOffer.value as? [String: Any] {
                        print(offerData)
                        if let qid = offerData["quizId"] as? String {
                            print(qid)
                            if qid == quizId {
                                isOfferAvailable = true
                                let offer = self.getOfferInformationFromFirebase(valueDict: offerData)
                                offersData.append(offer)
                            }
                        }
                    }
                }
                if isOfferAvailable{
                    // Offer successfully found
                    completion(true, offersData)
                }else{
                    //No Offer found for this quiz
                    completion(false, nil)
                }
            }
            else {
                completion(false, nil)
            }
        }
    }
    
    //Getting Address and ImageUrl from BusinessUser using Offer SponsorId Into Firebase
    func getBusinessUserDetailsUsingOfferIntoFirebase(sponsorId: String, completion: @escaping(Bool, Dictionary<String, String>?) -> ()) {
        guard let ref = databaseRef else {
            return
        }
        let childRef = ref.child(FbNode.kKeyBussinessUser).child(sponsorId)
//        childRef.keepSynced(true)
        childRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                //Business User exist
                var businessUser = [String: String]()
                if let user = snapshot.value as? [String: Any] {
                    if let imageURL = user["profileImage"] as? String {
                        businessUser[FbBusinessUserKey.kKeyImageUrl] = imageURL
                    }
                    if let address = user["address"] as? String {
                        businessUser[FbBusinessUserKey.kKeyAddress] = address
                    }
                }
                completion(true, businessUser)
            }
            else {
                //Business User doesnot exist
                completion(false, nil)
            }
        }
    }

    func storeNotificationDataForServer(notificationInfoDict : [String:Any],completion: @escaping(Bool,String?)  -> ()){
        var notificationInfo = notificationInfoDict
        guard let ref = databaseRef else {
            completion(false, nil)
            return
        }
        let notificationNodeKey = ref.child(FbNode.kKeyNotificationNode).childByAutoId().key
        notificationInfo[FbNotificationKey.kKeyNotificationId] = notificationNodeKey
        notificationInfo[FbNotificationKey.kKeyTimestamp] = ServerValue.timestamp()
        let notificationNodeRef = ref.child(FbNode.kKeyNotificationNode).child(notificationNodeKey)
        print(notificationInfo)
        notificationNodeRef.updateChildValues(notificationInfo) { (error, ref) in
            if let err = error{
                completion(false,err.localizedDescription)
            }
            completion(true, "Successfully Added Notification")
        }
    }
    
    //Get Quiz Data, QuizHistory and Offer on Particular Quiz Played
    func getOfferAndQuizDetailsUsingHistory(userId: String, quizId: String, completion: @escaping (Bool, QuizHistory?, Quiz?, [Offer]?) -> ()) {
        var offers = [Offer]()
        guard let ref = databaseRef else {
            return
        }
        let childRef = ref.child(FbNode.kKeyQuizHistory).child(userId).child(quizId)
//        childRef.keepSynced(true)
        childRef.observe(.value) { (snapshot) in
            if snapshot.exists() {
                if let quizHistoryData = snapshot.value as? [String: Any] {
                    let quizHistory = self.getQuizHistoryInformationFromFirebase(dict: quizHistoryData)
                    
                    let childsRef = ref.child(FbNode.kKeyQuizNode).child(quizId)
//                    childsRef.keepSynced(true)
                    childsRef.observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists() {
                            if let quizDict = snapshot.value as? [String: Any] {
                                let quizData = self.getQuizInformationFromFirebase(dict: quizDict)
                                
                                let offerRef = ref.child(FbNode.kKeyLockedOffer).child(userId).child(quizId)
//                                offerRef.keepSynced(true)
                                offerRef.observeSingleEvent(of: .value) { (snapshot) in
                                    if let allOffersDict = snapshot.value as? [String: Any]{
                                        for eachOffer in  allOffersDict{
                                            if let offerDict = eachOffer.value as? [String: Any]{
                                                offers.append(self.getOfferInformationFromFirebase(valueDict: offerDict))
                                            }
                                        }
                                        completion(true, quizHistory, quizData, offers)
                                    }else{
                                        //No Offer found for this user Id & Quiz Id
                                        completion(true, quizHistory, quizData, nil)
                                    }
                                }
                            }
                        }
                        else {
                            //No Quiz in Quizzes table
                            completion(true, quizHistory, nil, nil)
                        }
                    })
                    
                }
            }
            else {
                //No Quiz in History
                completion(false, nil, nil, nil)
            }
        }
    }
    
    func getMinimumNumberOFQuestionForUpload(completion: @escaping (Bool, Int?) -> ()){
        guard let ref = databaseRef else {
            completion(false, nil)
            return
        }
        let childRef = ref.child(FbNode.kKeyGeneralSettings)
        childRef.keepSynced(true)
        childRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                if let generalSettingDict = snapshot.value as? [String: Any]{
                    if let minQuestion = generalSettingDict[FbGeneralSettingKey.kKeyMin_questions] as? Int{
                        completion(true, minQuestion)
                    }
                }
            }
        }
    }
    
}
