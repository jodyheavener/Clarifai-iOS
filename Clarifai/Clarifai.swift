import UIKit
import Alamofire

/** All available Clarifai recognition types */
enum ClarifaiRecognitionType {
    case Tag, Color
}

/** All available Models to apply to Clarifai Tag recognizition */
enum ClarifaiTagModel {
    case General, NSFW, Weddings, Travel, Food
}

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
    
    enum DataInputType {
        case Image, Video, URL
    }
    
    init(clientID: String, clientSecret: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        
        self.loadAccessToken()
    }
    
    // MARK: Public Methods
    
    func recognize(type: ClarifaiRecognitionType, image: UIImage, model: ClarifaiTagModel = .General, completion: (AnyObject?, NSError?) -> Void) {
    
    }
    
    func recognize(type: ClarifaiRecognitionType, images: Array<UIImage>, model: ClarifaiTagModel = .General, completion: (AnyObject?, NSError?) -> Void) {
        
    }
    
    func recognize(type: ClarifaiRecognitionType, url: String, model: ClarifaiTagModel = .General, completion: (AnyObject?, NSError?) -> Void) {
        
    }
    
    func recognize(type: ClarifaiRecognitionType, urls: Array<String>, model: ClarifaiTagModel = .General, completion: (AnyObject?, NSError?) -> Void) {
        
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
    
    // MARK: Helper Methods

    
}
