import UIKit
import Alamofire

// MARK: - Configuration Values

struct ClarifaiConfig {
    static let BaseURL: String = "https://api.clarifai.com/v1"
    static let AppID: String = "com.clarifai.Clarifai.AppID"
    static let AccessToken: String = "com.clarifai.Clarifai.AccessToken"
    static let AccessTokenExpiration: String = "com.clarifai.Clarifai.AccessTokenExpiration"
    static let MinTokenLifetime: NSTimeInterval = 60
}

enum ClarifaiRecognitionType {
    case Tag, Color
}

enum ClarifaiTagModel {
    case General, NSFW, Weddings, Travel, Food
}

// MARK: - Main Class Setup

/** Provides access to Clarifai image recognition services */
class Clarifai {
    var clientID: String
    var clientSecret: String
    var accessToken: String?
    var accessTokenExpiration: NSDate?
    
    enum DataInputType {
        case Image, Video, URL
    }
    
    init(clientID: String, clientSecret: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        
        self.loadAccessToken()
    }
    
    // MARK: Public Methods
    

    
    // MARK: Access Token Management
    
    private func loadAccessToken() {
        let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        if self.clientID != userDefaults.stringForKey(ClarifaiConfig.AppID) {
            self.invalidateAccessToken()
        } else {
            self.accessToken = userDefaults.stringForKey(ClarifaiConfig.AccessToken)!
            self.accessTokenExpiration = userDefaults.objectForKey(ClarifaiConfig.AccessTokenExpiration)! as? NSDate
        }
    }
    
    private func saveAccessToken(response: ClarifaiAccessTokenResponse) {
        if let accessToken = response.accessToken, expiresIn = response.expiresIn {
            let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
            let expiration: NSDate = NSDate(timeIntervalSinceNow: expiresIn)
            
            userDefaults.setValue(self.clientID, forKey: ClarifaiConfig.AppID)
            userDefaults.setValue(accessToken, forKey: ClarifaiConfig.AccessToken)
            userDefaults.setValue(expiration, forKey: ClarifaiConfig.AccessTokenExpiration)
            userDefaults.synchronize()
            
            self.accessToken = accessToken
            self.accessTokenExpiration = expiration
        }
    }
    
    private func invalidateAccessToken() {
        let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        userDefaults.removeObjectForKey(ClarifaiConfig.AppID)
        userDefaults.removeObjectForKey(ClarifaiConfig.AccessToken)
        userDefaults.removeObjectForKey(ClarifaiConfig.AccessTokenExpiration)
        userDefaults.synchronize()
        
        self.accessToken = nil
        self.accessTokenExpiration = nil
    }
    
    private func validateAccessToken(handler: (error: NSError?) -> Void) {
        if self.accessToken != nil && self.accessTokenExpiration != nil && self.accessTokenExpiration?.timeIntervalSinceNow > ClarifaiConfig.MinTokenLifetime {
            handler(error: nil)
        } else {
            let params: Dictionary<String, AnyObject> = [
                "grant_type": "client_credentials",
                "client_id": self.clientID,
                "client_secret": self.clientSecret
            ]
            
            Alamofire.request(.POST, ClarifaiConfig.BaseURL.stringByAppendingString("/token"), parameters: params)
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
    

    
}

// MARK: - Access Token Response

class ClarifaiAccessTokenResponse: NSObject {
    var accessToken: String?
    var expiresIn: NSTimeInterval?
    
    init(responseJSON: NSDictionary) {
        self.accessToken = responseJSON["access_token"] as? String
        self.expiresIn = max(responseJSON["expires_in"] as! Double, ClarifaiConfig.MinTokenLifetime)
    }
}

// MARK: - API Result Objects

