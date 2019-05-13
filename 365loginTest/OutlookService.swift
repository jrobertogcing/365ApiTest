//
//  OutlookService.swift
//  365loginTest
//
//  Created by José González on 5/11/19.
//  Copyright © 2019 José González. All rights reserved.
//

import Foundation
import p2_OAuth2
import SwiftyJSON

class OutlookService {
    
    private var userEmail: String

    // Configure the OAuth2 framework for Azure
    private static let oauth2Settings = [
        "client_id" : "766161fa-50c8-494d-ab11-4fd35e82d925",
        "authorize_uri": "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
        "token_uri": "https://login.microsoftonline.com/common/oauth2/v2.0/token",
        "scope": "openid profile offline_access User.Read Mail.Read",
        "redirect_uris": ["swift-tutorial://oauth2/callback"],
        "verbose": true,
        ] as OAuth2JSON
    
    private static var sharedService: OutlookService = {
        let service = OutlookService()
        return service
    }()
    
    private let oauth2: OAuth2CodeGrant
    
    private init() {
        userEmail = ""
        oauth2 = OAuth2CodeGrant(settings: OutlookService.oauth2Settings)
        oauth2.authConfig.authorizeEmbedded = true
    }
    
    class func shared() -> OutlookService {
        return sharedService
    }
    
    var isLoggedIn: Bool {
        get {
            return oauth2.hasUnexpiredAccessToken() || oauth2.refreshToken != nil
        }
    }
    
    func handleOAuthCallback(url: URL) -> Void {
        oauth2.handleRedirectURL(url)
    }
    
    func login(from: AnyObject, callback: @escaping (String? ) -> Void) -> Void {
        oauth2.authorizeEmbedded(from: from) {
            result, error in
            if let unwrappedError = error {
                callback(unwrappedError.description)
            } else {
                if let unwrappedResult = result, let token = unwrappedResult["access_token"] as? String {
                    // Print the access token to debug log
                    NSLog("Access token: \(token)")
                    callback(nil)
                }
            }
        }
    }
    
    func logout() -> Void {
       // Borrado de cookies, no ayuda
        let storage = HTTPCookieStorage.shared
        storage.cookies?.forEach() { storage.deleteCookie($0) }
        oauth2.forgetTokens()

    }
    
    //Funcion de prueba, no funcionó
    func forgetUser() -> Void {
        //oauth2.abortAuthorization()
        oauth2.forgetTokens()
        oauth2.forgetClient()
        let secItemClasses =  [kSecClassGenericPassword, kSecClassInternetPassword, kSecClassCertificate, kSecClassKey, kSecClassIdentity]
        for itemClass in secItemClasses {
            let spec: NSDictionary = [kSecClass: itemClass]
            SecItemDelete(spec)
        }
    }
    
    func makeApiCall(api: String, params: [String: String]? = nil, callback: @escaping (JSON?) -> Void) -> Void {
        // Build the request URL
        var urlBuilder = URLComponents(string: "https://graph.microsoft.com")!
        urlBuilder.path = api
        
        if let unwrappedParams = params {
            // Add query parameters to URL
            urlBuilder.queryItems = [URLQueryItem]()
            for (paramName, paramValue) in unwrappedParams {
                urlBuilder.queryItems?.append(
                    URLQueryItem(name: paramName, value: paramValue))
            }
        }
        
        let apiUrl = urlBuilder.url!
        NSLog("Making request to \(apiUrl)")
        
        var req = oauth2.request(forURL: apiUrl)
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let loader = OAuth2DataLoader(oauth2: oauth2)
        
        // Uncomment this line to get verbose request/response info in
        // Xcode output window
        //loader.logger = OAuth2DebugLogger(.trace)
        
        loader.perform(request: req) {
            response in
            do {
                let dict = try response.responseJSON()
                DispatchQueue.main.async {
                    let result = JSON(dict)
                    callback(result)
                }
            }
            catch let error {
                DispatchQueue.main.async {
                    let result = JSON(error)
                    callback(result)
                }
            }
        }
    }
    
    func getUserEmail(callback: @escaping (String?) -> Void) -> Void {
        // If we don't have the user's email, get it from
        // the API
        if (userEmail.isEmpty) {
            makeApiCall(api: "/v1.0/me") {
                result in
                if let unwrappedResult = result {
                    var email = unwrappedResult["mail"].stringValue
                    if (email.isEmpty) {
                        // Fallback to userPrincipalName ONLY if mail is empty
                        email = unwrappedResult["userPrincipalName"].stringValue
                    }
                    self.userEmail = email
                    callback(email)
                } else {
                    callback(nil)
                }
            }
        } else {
            callback(userEmail)
        }
    }
    func getInboxMessages(callback: @escaping (JSON?) -> Void) -> Void {
        let apiParams = [
            "$select": "subject,receivedDateTime,from",
            "$orderby": "receivedDateTime DESC",
            "$top": "10"
        ]
        
        makeApiCall(api: "/v1.0/me/mailfolders/inbox/messages", params: apiParams) {
            result in
            callback(result)
        }
    }
}
