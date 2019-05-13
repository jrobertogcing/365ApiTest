//
//  ViewController.swift
//  365loginTest
//
//  Created by José González on 5/11/19.
//  Copyright © 2019 José González. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate{

    let service = OutlookService.shared()

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var userEmailLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    var dataSource: MessagesDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Al parecer no ayuda, el borrado de cookies
        let storage = HTTPCookieStorage.shared
        storage.cookies?.forEach() { storage.deleteCookie($0) }

        print(service.isLoggedIn)
        
        setLogInState(loggedIn: service.isLoggedIn)
        if (service.isLoggedIn) {
            loadUserData()
        }
        
        tableView.delegate = self
      // tableView.estimatedRowHeight = 300;
       // tableView.rowHeight = UITableView.automaticDimension
     
    }
    override func viewDidAppear(_ animated: Bool) {
        userEmailLabel.text = ""
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    @IBAction func logInButtonAction(_ sender: UIButton) {
        
        if (service.isLoggedIn) {
            // Logout
            service.logout()
            userEmailLabel.text = ""
            setLogInState(loggedIn: false)
        
            tableView.reloadData()
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
                
                self.service.getInboxMessages() {
                    messages in
                    if let unwrappedMessages = messages {
                        self.dataSource = MessagesDataSource(messages: unwrappedMessages["value"].arrayValue)
                        self.tableView.dataSource = self.dataSource
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
}

