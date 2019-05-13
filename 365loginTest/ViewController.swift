//
//  ViewController.swift
//  365loginTest
//
//  Created by José González on 5/11/19.
//  Copyright © 2019 José González. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let service = OutlookService.shared()

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var userEmailLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //El usuario esta logeado o no.
        
        let storage = HTTPCookieStorage.shared
        storage.cookies?.forEach() { storage.deleteCookie($0) }

        print(service.isLoggedIn)
      //  removeCookies()
       //service.forgetUser()
        
        setLogInState(loggedIn: service.isLoggedIn)
        if (service.isLoggedIn) {
            loadUserData()
        }
        //service.logout()
       // service.forgetUser()
//        let storage = HTTPCookieStorage.shared
//        storage.cookies?.forEach() { storage.deleteCookie($0) }
    }
    override func viewDidAppear(_ animated: Bool) {
        userEmailLabel.text = ""
    }
    
    @IBAction func logInButtonAction(_ sender: UIButton) {
//        if (service.isLoggedIn) {
//            // Logout
//            service.logout()
//           // service.forgetUser()
//            setLogInState(loggedIn: false)
//        } else {
//            // Login
//            let storage = HTTPCookieStorage.shared
//            storage.cookies?.forEach() { storage.deleteCookie($0) }
//
//
//            service.login(from: self) {
//                error in
//                if let unwrappedError = error {
//                    NSLog("Error logging in: \(unwrappedError)")
//                } else {
//                    NSLog("Successfully logged in.")
//                    self.setLogInState(loggedIn: true)
//                }
//            }
//        }
        
        if (service.isLoggedIn) {
            // Logout
            service.logout()
            userEmailLabel.text = ""
            setLogInState(loggedIn: false)
        } else {
            // Login
            service.login(from: self) {
                error in
                if let unwrappedError = error {
                    NSLog("Error logging in: \(unwrappedError)")
                } else {
                    NSLog("Successfully logged in.")
                    self.setLogInState(loggedIn: true)
                    self.loadUserData()
                }
            }
        }
    }
    
    func setLogInState(loggedIn: Bool) {
        if (loggedIn) {
            loginButton.setTitle("Log Out", for: UIControl.State.normal)
        }
        else {
            loginButton.setTitle("Log In", for: UIControl.State.normal)
        }
    }
    
    func removeCookies(){
        _ = HTTPCookie.self
        let cookieJar = HTTPCookieStorage.shared
        
        for cookie in cookieJar.cookies! {
            cookieJar.deleteCookie(cookie)
        }
    }
    // Delete Cookies
    func deleteCookies() {
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }
    
    // Delete Cache
    func deleteCache() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
    func loadUserData() {
        service.getUserEmail() {
            email in
            if let unwrappedEmail = email {
                NSLog("Hello \(unwrappedEmail)")
                self.userEmailLabel.text = unwrappedEmail
                
                self.service.getInboxMessages() {
                    messages in
                    if let unwrappedMessages = messages {
                        for (message) in unwrappedMessages["value"].arrayValue {
                            NSLog(message["subject"].stringValue)
                        }
                    }
                }
            }
        }
    }
    
}

