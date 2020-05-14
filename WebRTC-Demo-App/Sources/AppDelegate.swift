//
//  AppDelegate.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//
import netfox
import UIKit
import IQKeyboardManagerSwift


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    internal var window: UIWindow?
    
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
       let loginVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "loginVC") as UIViewController
         window.rootViewController = UINavigationController(rootViewController: loginVC)
        window.makeKeyAndVisible()
        self.window = window
        
        IQKeyboardManager.shared.enable = true
        NFX.sharedInstance().start()
        
        return true
    }
    
}

