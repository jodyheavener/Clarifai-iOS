import UIKit
import Alamofire

/** Provides access to Clarifai image recognition services */
class Clarifai {
    var clientID: String
    var clientSecret: String
    var accessToken: String?
    var accessTokenExpiration: NSDate?
    
    init(clientID: String, clientSecret: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        
        self.loadAccessToken()
    }
    
    // MARK: Public Methods
    
    /** Classify and tag a single image */
    func tag(image: UIImage, completion: (ClarifaiResponse?, NSError?) -> Void) {
        self.tag(image, model: .General, completion: completion)
    }
    
    /** Classify and tag a single image using a specific model */
    func tag(image: UIImage, model: ClarifaiTagModel, completion: (ClarifaiResponse?, NSError?) -> Void) {
        self.tag([image], model: model, completion: completion)
    }
    
    /** Classify and tag multiple images */
    func tag(images: Array<UIImage>, completion: (ClarifaiResponse?, NSError?) -> Void) {
        self.tag(images, model: .General, completion: completion)
    }
    
    /** Classify and tag multiple images using a specific model */
    func tag(images: Array<UIImage>, model: ClarifaiTagModel, completion: (ClarifaiResponse?, NSError?) -> Void) {
        self.recognize(.Tag, data: images, dataType: .Image, model: model, completion: completion)
    }
    
    /** Classify and tag the image at a URL */
    func tag(url: String, completion: (ClarifaiResponse?, NSError?) -> Void) {
        self.tag(url, model: .General, completion: completion)
    }
    
    /** Classify and tag the image at a URL using a specific model */
    func tag(url: String, model: ClarifaiTagModel, completion: (ClarifaiResponse?, NSError?) -> Void) {
        self.tag([url], model: model, completion: completion)
    }
    
    /** Classify and tag images at multiple URLs */
    func tag(urls: Array<String>, completion: (ClarifaiResponse?, NSError?) -> Void) {
        self.tag(urls, model: .General, completion: completion)
    }
    
    /** Classify and tag images at multiple URLs using a specific model */
    func tag(urls: Array<String>, model: ClarifaiTagModel, completion: (ClarifaiResponse?, NSError?) -> Void) {
        self.recognize(.Tag, data: urls, dataType: .URL, model: model, completion: completion)
    }
    
// Disabled until support for Color at multiop endpoint is available
//    /** Detect colors in a single image */
//    func color(image: UIImage, completion: (ClarifaiResponse?, NSError?) -> Void) {
//        self.color([image], completion: completion)
//    }
//    
//    /** Detect colors in multiple images */
//    func color(images: Array<UIImage>, completion: (ClarifaiResponse?, NSError?) -> Void) {
//        self.recognize(.Color, data: images, dataType: .Image, model: nil, completion: completion)
//    }
//    
//    /** Detect colors in a single image at a URL */
//    func color(url: String, completion: (ClarifaiResponse?, NSError?) -> Void) {
//        self.color([url], completion: completion)
//    }
//    
//    /** Detect colors in images at multiple URLs */
//    func color(urls: Array<String>, completion: (ClarifaiResponse?, NSError?) -> Void) {
//        self.recognize(.Color, data: urls, dataType: .URL, model: nil, completion: completion)
//    }
    
    // MARK: Access Token Management
    
    private func loadAccessToken() {
        let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        if self.clientID != userDefaults.stringForKey(ClarifaiKeys.AppID) {
            self.invalidateAccessToken()
        } else {
            self.accessToken = userDefaults.stringForKey(ClarifaiKeys.AccessToken)!
            self.accessTokenExpiration = userDefaults.objectForKey(ClarifaiKeys.AccessTokenExpiration)! as? NSDate
        }
    }
    
    private func saveAccessToken(response: ClarifaiAccessTokenResponse) {
        if let accessToken = response.accessToken, expiresIn = response.expiresIn {
            let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
            let expiration: NSDate = NSDate(timeIntervalSinceNow: expiresIn)
            
            userDefaults.setValue(self.clientID, forKey: ClarifaiKeys.AppID)
            userDefaults.setValue(accessToken, forKey: ClarifaiKeys.AccessToken)
            userDefaults.setValue(expiration, forKey: ClarifaiKeys.AccessTokenExpiration)
            userDefaults.synchronize()
            
            self.accessToken = accessToken
            self.accessTokenExpiration = expiration
        }
    }
    
    private func invalidateAccessToken() {
        let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        userDefaults.removeObjectForKey(ClarifaiKeys.AppID)
        userDefaults.removeObjectForKey(ClarifaiKeys.AccessToken)
        userDefaults.removeObjectForKey(ClarifaiKeys.AccessTokenExpiration)
        userDefaults.synchronize()
        
        self.accessToken = nil
        self.accessTokenExpiration = nil
    }
    
    private func validateAccessToken(handler: (error: NSError?) -> Void) {
        if self.accessToken != nil && self.accessTokenExpiration != nil && self.accessTokenExpiration?.timeIntervalSinceNow > ClarifaiKeys.MinTokenLifetime {
            handler(error: nil)
        } else {
            let params: Dictionary<String, AnyObject> = [
                "grant_type": "client_credentials",
                "client_id": self.clientID,
                "client_secret": self.clientSecret
            ]
            
            Alamofire.request(.POST, ClarifaiKeys.BaseURL.stringByAppendingString("/token"), parameters: params)
                .validate()
                .responseJSON() { response in
                    switch response.result {
                    case .Success(let result):
                        let tokenResponse = ClarifaiAccessTokenResponse(responseJSON: result as! NSDictionary)
                        self.saveAccessToken(tokenResponse)
                    case .Failure(let error):
                        handler(error: error)
                    }
                }
        }
    }
    
    // MARK: Helper Methods
    
    private func recognize(type: ClarifaiRecognizeType, data: Array<AnyObject>, dataType: ClarifaiDataType, model: ClarifaiTagModel?, completion: (ClarifaiResponse?, NSError?) -> Void) {
        self.processRecognition(type, formData: { (formData) in
            switch type {
            case .Tag:
                switch model! {
                case .General:
                    formData.appendBodyPart(data: "general-v1.3".dataUsingEncoding(NSUTF8StringEncoding)!, name: "model")
                case .NSFW:
                    formData.appendBodyPart(data: "nsfw-v1.0".dataUsingEncoding(NSUTF8StringEncoding)!, name: "model")
                case .Weddings:
                    formData.appendBodyPart(data: "weddings-v1.0".dataUsingEncoding(NSUTF8StringEncoding)!, name: "model")
                case .Travel:
                    formData.appendBodyPart(data: "travel-v1.0".dataUsingEncoding(NSUTF8StringEncoding)!, name: "model")
                case .Food:
                    formData.appendBodyPart(data: "food-items-v0.1".dataUsingEncoding(NSUTF8StringEncoding)!, name: "model")
                }
            // Disabled until support for Color at multiop endpoint is available
            // case .Color:
            }
            
            switch dataType {
            case .Image:
                for image in data as! Array<UIImage> {
                    let size = CGSizeMake(320, 320 * image.size.height / image.size.width)
                    
                    UIGraphicsBeginImageContext(size)
                    image.drawInRect(CGRectMake(0, 0, size.width, size.height))
                    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    formData.appendBodyPart(data: UIImageJPEGRepresentation(scaledImage, 0.9)!, name: "encoded_image", fileName: "image.jpg", mimeType: "image/jpeg")
                }
            case .URL:
                for url in data as! Array<String> {
                    formData.appendBodyPart(data: url.dataUsingEncoding(NSUTF8StringEncoding)!, name: "url")
                }
            }
        }, completion: completion)
    }
    
    private func processRecognition(type: ClarifaiRecognizeType, formData: (formData: MultipartFormData) -> Void, completion: (ClarifaiResponse?, NSError?) -> Void) {
        self.validateAccessToken { (error) in
            if error != nil {
                return completion(nil, error)
            }
            
            var operationType: String
            
            switch type {
            case .Tag:
                operationType = "tag"
            // Disabled until support for Color at multiop endpoint is available
            // case .Color:
            //     operationType = "color"
            }
            
            Alamofire.upload(.POST, ClarifaiKeys.BaseURL.stringByAppendingString("/multiop"), headers: [
                "Authorization": "Bearer \(self.accessToken!)"
            ], multipartFormData: { multipartFormData in
                multipartFormData.appendBodyPart(data: operationType.dataUsingEncoding(NSUTF8StringEncoding)!, name: "op")
                formData(formData: multipartFormData)
            }, encodingCompletion: { (encodingResult) in
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.validate().responseJSON { response in
                        switch response.result {
                        case .Success(let result):
                            let results = ClarifaiResponse(type: type, dictionary: result as! Dictionary<NSObject, AnyObject>)
                            completion(results, nil)
                        case .Failure(let error):
                            completion(nil, error)
                        }
                    }
                case .Failure(let encodingError):
                    print(encodingError)
                }
            })
        }
    }
    
}

// MARK: - Internal Values

struct ClarifaiKeys {
    static let BaseURL: String = "https://api.clarifai.com/v1"
    static let ErrorDomain: String = "com.clarifai.Clarifai"
    static let AppID: String = "com.clarifai.Clarifai.AppID"
    static let AccessToken: String = "com.clarifai.Clarifai.AccessToken"
    static let AccessTokenExpiration: String = "com.clarifai.Clarifai.AccessTokenExpiration"
    static let MinTokenLifetime: NSTimeInterval = 60
}

enum ClarifaiRecognizeType {
    case Tag
//    case Color
}

enum ClarifaiDataType {
    case Image
    case URL
}

enum ClarifaiTagModel {
    case General
    case NSFW
    case Weddings
    case Travel
    case Food
}

// MARK: - Access Token Response

class ClarifaiAccessTokenResponse: NSObject {
    var accessToken: String?
    var expiresIn: NSTimeInterval?
    
    init(responseJSON: NSDictionary) {
        if let token = responseJSON["access_token"] as? String {
            self.accessToken = token
        }
        
        if let expires = responseJSON["expires_in"] as? Double {
            self.expiresIn = max(expires, ClarifaiKeys.MinTokenLifetime)
        }
    }
}

// MARK: - API Result Objects

class ClarifaiTag: NSObject {
    var documentID: String
    var labels: [String] = []
    var conceptIds: [String] = []
    var probabilities: [Float] = []
    
    init(dictionary dict: [NSObject : AnyObject]) {
        self.documentID = dict["docid_str"] as! String
        
        let result: [NSObject : AnyObject] = dict["result"] as! Dictionary<NSObject, AnyObject>
        let tag = result["tag"] as! Dictionary<NSObject, AnyObject>
        
        labels = tag["classes"] as! Array<String>
        conceptIds = tag["classes"] as! Array<String>
        probabilities = tag["probs"] as! Array<Float>
    }
}


// This is not complete
// Won't complete until support for Color at multiop endpoint is available
class ClarifaiColor: NSObject {
    var documentID: String
    
    init(dictionary dict: [NSObject : AnyObject]) {
        self.documentID = dict["docid_str"] as! String
    }
}

class ClarifaiResponse: NSObject {
    var statusCode: String
    var statusMessage: String
    var tags: [ClarifaiTag]?
    // Disabled until support for Color at multiop endpoint is available
    // var colors: [ClarifaiColor]?
    
    init(type: ClarifaiRecognizeType, dictionary dict: [NSObject : AnyObject]) {
        self.statusCode = dict["status_code"] as! String
        self.statusMessage = dict["status_msg"] as! String
        
        switch type {
        case .Tag:
            var tags: [ClarifaiTag] = []
            
            for result: [NSObject : AnyObject] in dict["results"] as! [Dictionary<NSObject, AnyObject>] {
                tags.append(ClarifaiTag(dictionary: result))
            }

            self.tags = tags
// Disabled until support for Color at multiop endpoint is available
//        case .Color:
//            var colors: [ClarifaiColor] = []
//            
//            for result: [NSObject : AnyObject] in dict["results"] as! [Dictionary<NSObject, AnyObject>] {
//                colors.append(ClarifaiColor(dictionary: result))
//            }
//            
//            self.colors = colors
        }
    }
}