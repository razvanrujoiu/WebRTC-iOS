//
//  LoginController.swift
//  WebRTC-Demo
//
//  Created by Razvan Rujoiu on 10/05/2020.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import UIKit

class LoginController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    private let config = Config.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
    }
    
    @IBAction func loginBtnPressed(_ sender: UIButton) {
        let mainVC = buildMainViewController()
        self.navigationController?.pushViewController(mainVC, animated: true)
        
    }
    
    private func buildMainViewController() -> MainViewController {
          
          let webRTCClient = WebRTCClient(iceServers: self.config.webRTCIceServers)
//          let signalClient = self.buildSignalingClient()
          let mainViewController = MainViewController(webRTCClient: webRTCClient)
          return mainViewController
      }
      
    
    // from the legacy signaling over websockets
      private func buildSignalingClient() -> SignalingClient {
          
          // iOS 13 has native websocket support. For iOS 12 or lower we will use 3rd party library.
          let webSocketProvider: WebSocketProvider
          
          if #available(iOS 13.0, *) {
              webSocketProvider = NativeWebSocket(url: self.config.signalingServerUrl)
          } else {
              webSocketProvider = StarscreamWebSocket(url: self.config.signalingServerUrl)
          }
          
          return SignalingClient(webSocket: webSocketProvider)
      }
}
