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
    private let config = Config.default
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        
        
        let loginVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "loginVC") as UIViewController
        let navController = UINavigationController(rootViewController: loginVC)
        
        
        if UserDefaults.standard.string(forKey: "phoneNumber") != nil {
            let webRTCClient = WebRTCClient(iceServers: self.config.webRTCIceServers)
            let mainViewController = MainViewController(webRTCClient: webRTCClient)
            navController.pushViewController(mainViewController, animated: true)
        }
        window.rootViewController = navController
        
        window.makeKeyAndVisible()
        self.window = window
        
        IQKeyboardManager.shared.enable = true
        NFX.sharedInstance().start()
        
        return true
    }
    
}

