import UIKit
import Alamofire

/** Provides access to the Clarifai image recognition services */
class Clarifai {
    var clientID: String
    var clientSecret: String
    var accessToken: String?
    var accessTokenExpiration: NSDate?

    struct Config {
        static let BaseURL: String = "https://api.clarifai.com/v1"
        static let AppID: String = "com.clarifai.Clarifai.AppID"
        static let AccessToken: String = "com.clarifai.Clarifai.AccessToken"
        static let AccessTokenExpiration: String = "com.clarifai.Clarifai.AccessTokenExpiration"
        static let MinTokenLifetime: NSTimeInterval = 60
    }
    
    init(clientID: String, clientSecret: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        
        self.loadAccessToken()
    }
    
    // MARK: Access Token Management
    
    private func loadAccessToken() {
        let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        if self.clientID != userDefaults.stringForKey(Config.AppID) {
            self.invalidateAccessToken()
        } else {
            self.accessToken = userDefaults.stringForKey(Config.AccessToken)!
            self.accessTokenExpiration = userDefaults.objectForKey(Config.AccessTokenExpiration)! as? NSDate
        }
    }
    
    private func saveAccessToken(response: AccessTokenResponse) {
        if let accessToken = response.accessToken, expiresIn = response.expiresIn {
            let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
            let expiration: NSDate = NSDate(timeIntervalSinceNow: expiresIn)
            
            userDefaults.setValue(self.clientID, forKey: Config.AppID)
            userDefaults.setValue(accessToken, forKey: Config.AccessToken)
            userDefaults.setValue(expiration, forKey: Config.AccessTokenExpiration)
            userDefaults.synchronize()
            
            self.accessToken = accessToken
            self.accessTokenExpiration = expiration
        }
    }
    
    private func invalidateAccessToken() {
        let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        userDefaults.removeObjectForKey(Config.AppID)
        userDefaults.removeObjectForKey(Config.AccessToken)
        userDefaults.removeObjectForKey(Config.AccessTokenExpiration)
        userDefaults.synchronize()
        
        self.accessToken = nil
        self.accessTokenExpiration = nil
    }
    
    private func validateAccessToken(handler: (error: NSError?) -> Void) {
        if self.accessToken != nil && self.accessTokenExpiration != nil && self.accessTokenExpiration?.timeIntervalSinceNow > Config.MinTokenLifetime {
            handler(error: nil)
        } else {
            let params: Dictionary<String, AnyObject> = [
                "grant_type": "client_credentials",
                "client_id": self.clientID,
                "client_secret": self.clientSecret
            ]
            
            Alamofire.request(.POST, Config.BaseURL.stringByAppendingString("/token"), parameters: params)
                .validate()
                .responseJSON() { response in
                    switch response.result {
                    case .Success(let result):
                        let tokenResponse = AccessTokenResponse(responseJSON: result as! NSDictionary)
                        self.saveAccessToken(tokenResponse)
                    case .Failure(let error):
                        handler(error: error)
                    }
                }
        }
    }
    
    private class AccessTokenResponse: NSObject {
        var accessToken: String?
        var expiresIn: NSTimeInterval?
        
        init(responseJSON: NSDictionary) {
            self.accessToken = responseJSON["access_token"] as? String
            self.expiresIn = max(responseJSON["expires_in"] as! Double, Clarifai.Config.MinTokenLifetime)
        }
    }
    
    // MARK: Recognition Processing
    
    /** All available Clarifai recognition types */
    enum RecognitionType: String {
        case Tag = "tag"
        case Color = "color"
    }
    
    /** All available Models to apply to Clarifai Tag recognizition */
    enum TagModel: String {
        case General = "general-v1.3"
        case NSFW = "nsfw-v1.0"
        case Weddings = "weddings-v1.0"
        case Travel = "travel-v1.0"
        case Food = "food-items-v0.1"
    }
    
    /** All available ways to upload data to Clarifai for recognizition */
    private enum DataInputType {
        case Image, URL
    }
    
    /** Recognize components of one or more images via UIImage */
    func recognize(type: RecognitionType = .Tag, image: Array<UIImage>, model: TagModel = .General, completion: (AnyObject?, NSError?) -> Void) {
        self.process(type, dataInputType: .Image, data: image, model: model, completion: completion)
    }
    
    /** Recognize components of one or more images via string URL */
    func recognize(type: RecognitionType = .Tag, url: Array<String>, model: TagModel = .General, completion: (AnyObject?, NSError?) -> Void) {
        self.process(type, dataInputType: .URL, data: url, model: model, completion: completion)
    }

    private func process(type: RecognitionType, dataInputType: DataInputType, data: Array<AnyObject>, model: TagModel, completion: (AnyObject?, NSError?) -> Void) {
        self.validateAccessToken { (error) in
            if error != nil {
                return completion(nil, error)
            }
            
            let multiop = data.count > 1
            let endpoint = multiop ? "/multiop" : "/\(type.rawValue)"
            
            Alamofire.upload(.POST, Config.BaseURL.stringByAppendingString(endpoint), headers: [
                "Authorization": "Bearer \(self.accessToken!)"
            ], multipartFormData: { multipartFormData in
                if multiop {
                    multipartFormData.appendBodyPart(data: type.rawValue.dataUsingEncoding(NSUTF8StringEncoding)!, name: "op")
                }
                
                switch dataInputType {
                case .URL:
                    for url in data as! Array<String> {
                        multipartFormData.appendBodyPart(data: url.dataUsingEncoding(NSUTF8StringEncoding)!, name: "url")
                    }
                case .Image:
                    for image in data as! Array<UIImage> {
                        let size = CGSizeMake(320, 320 * image.size.height / image.size.width)
                        
                        UIGraphicsBeginImageContext(size)
                        image.drawInRect(CGRectMake(0, 0, size.width, size.height))
                        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        
                        multipartFormData.appendBodyPart(data: UIImageJPEGRepresentation(scaledImage, 0.9)!, name: "encoded_image", fileName: "image.jpg", mimeType: "image/jpeg")
                    }
                }
                
                if type == .Tag {
                    multipartFormData.appendBodyPart(data: model.rawValue.dataUsingEncoding(NSUTF8StringEncoding)!, name: "model")
                }
            }, encodingCompletion: { (encodingResult) in
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.validate().responseJSON { response in
                        switch response.result {
                        case .Success(let result):
//                            let results = ClarifaiResponse(type: type, dictionary: result as! Dictionary<NSObject, AnyObject>)
                            completion(result, nil)
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
