//
//  VideoViewController.swift
//  WebRTC
//
//  Created by Stasel on 21/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import UIKit
import WebRTC

class VideoViewController: UIViewController {

    @IBOutlet private weak var localVideoView: UIView?
    private let webRTCClient: WebRTCClient
    private var isFrontCamera: Bool = true

    init(webRTCClient: WebRTCClient) {
        self.webRTCClient = webRTCClient
        super.init(nibName: String(describing: VideoViewController.self), bundle: Bundle.main)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideoRendering()
    }
    
    private func setupVideoRendering() {
        #if arch(arm64)
        // Using metal (arm64 only)
        let localRenderer = RTCMTLVideoView(frame: self.localVideoView?.frame ?? CGRect.zero)
        let remoteRenderer = RTCMTLVideoView(frame: self.view.frame)
        localRenderer.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        remoteRenderer.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        localRenderer.videoContentMode = .scaleAspectFill
        remoteRenderer.videoContentMode = .scaleAspectFill
        #else
        // Using OpenGLES for the rest
        let localRenderer = RTCEAGLVideoView(frame: self.localVideoView?.frame ?? CGRect.zero)
        let remoteRenderer = RTCEAGLVideoView(frame: self.view.frame)
        localRenderer.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        remoteRenderer.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        #endif
        
        self.webRTCClient.startCaptureLocalVideo(renderer: localRenderer, position: AVCaptureDevice.Position.front)
        self.webRTCClient.renderRemoteVideo(to: remoteRenderer)
        
        // TODO find a way to refactor this, the views are stacking
        
        if let localVideoView = self.localVideoView {
            self.embedView(localRenderer, into: localVideoView)
        }
        self.embedView(remoteRenderer, into: self.view)
        
        self.view.sendSubviewToBack(remoteRenderer)
        
    }
    
    
    private func embedView(_ view: UIView, into containerView: UIView) {
        
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        containerView.layoutIfNeeded()
    }
    
    @IBAction private func backDidTap(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    @IBAction func rotateCamera(_ sender: UIButton) {
//        if self.isFrontCamera {
//            self.webRTCClient.startCaptureLocalVideo(renderer: <#T##RTCVideoRenderer#>, position: <#T##AVCaptureDevice.Position#>)
//            isFrontCamera = false
//        } else {
//            self.setupVideoRendering(position: .front)
//            isFrontCamera = true
//        }
    }
}
