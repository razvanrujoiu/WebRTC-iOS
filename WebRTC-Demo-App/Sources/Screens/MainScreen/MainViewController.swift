//
//  ViewController.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import UIKit
import AVFoundation
import WebRTC
import CocoaMQTT
import CocoaAsyncSocket
import CallKit
import SkyFloatingLabelTextField

class MainViewController: UIViewController {

//    private let signalClient: SignalingClient
    private let webRTCClient: WebRTCClient
    private lazy var videoViewController = VideoViewController(webRTCClient: self.webRTCClient)
    
    @IBOutlet private weak var speakerButton: UIButton?
    @IBOutlet private weak var signalingStatusLabel: UILabel?
    @IBOutlet private weak var localSdpStatusLabel: UILabel?
//    @IBOutlet private weak var localCandidatesLabel: UILabel?
    @IBOutlet private weak var remoteSdpStatusLabel: UILabel?
//    @IBOutlet private weak var remoteCandidatesLabel: UILabel?
    @IBOutlet private weak var muteButton: UIButton?
    @IBOutlet private weak var webRTCStatusLabel: UILabel?
    
    @IBOutlet weak var conversationOptionsStackView: UIStackView!
    @IBOutlet weak var phoneNumberTextField: SkyFloatingLabelTextFieldWithIcon!
    var mqtt: CocoaMQTT!
    
    private var signalingConnected: Bool = false {
        didSet {
            DispatchQueue.main.async {
                if self.signalingConnected {
                    self.signalingStatusLabel?.text = "Connected"
                    self.signalingStatusLabel?.textColor = UIColor.green
                }
                else {
                    self.signalingStatusLabel?.text = "Not connected"
                    self.signalingStatusLabel?.textColor = UIColor.red
                }
            }
        }
    }
    
    private var hasLocalSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.localSdpStatusLabel?.text = self.hasLocalSdp ? "✅" : "❌"
            }
        }
    }
    
//    private var localCandidateCount: Int = 0 {
//        didSet {
//            DispatchQueue.main.async {
//                self.localCandidatesLabel?.text = "\(self.localCandidateCount)"
//            }
//        }
//    }
    
    private var hasRemoteSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.remoteSdpStatusLabel?.text = self.hasRemoteSdp ? "✅" : "❌"
            }
        }
    }
    
//    private var remoteCandidateCount: Int = 0 {
//        didSet {
//            DispatchQueue.main.async {
//                self.remoteCandidatesLabel?.text = "\(self.remoteCandidateCount)"
//            }
//        }
//    }
    
    private var speakerOn: Bool = false {
        didSet {
            let title = "Speaker: \(self.speakerOn ? "On" : "Off" )"
            self.speakerButton?.setTitle(title, for: .normal)
        }
    }
    
    private var mute: Bool = false {
        didSet {
            let title = "Mute: \(self.mute ? "on" : "off")"
            self.muteButton?.setTitle(title, for: .normal)
        }
    }
    
    init(webRTCClient: WebRTCClient) {
//        self.signalClient = signalClient
        self.webRTCClient = webRTCClient
        super.init(nibName: String(describing: MainViewController.self), bundle: Bundle.main)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        self.signalingConnected = false
        self.hasLocalSdp = false
        self.hasRemoteSdp = false
        self.speakerOn = false
        self.webRTCStatusLabel?.text = "New"
        self.conversationOptionsStackView.isHidden = true
        self.webRTCClient.delegate = self
//        self.signalClient.delegate = self
//        self.signalClient.connect()
        self.setupMqtt()
    }
    
    func setupMqtt() {
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        mqtt = CocoaMQTT(clientID: clientID, host: "test.mosquitto.org", port: 1883)
        mqtt.logLevel = .debug
        mqtt!.keepAlive = 60
        mqtt.allowUntrustCACertificate = true
        mqtt!.delegate = self
        mqttConnect()
    }
    
    @objc
    func mqttConnect() {
        _ = mqtt!.connect()
    }
    

    
    @IBAction private func offerDidTap(_ sender: UIButton) {
        self.webRTCClient.offer { (sdp) in
            self.hasLocalSdp = true
            let message = Message.sdp(SessionDescription(from: sdp))
            self.encodeMessageAndPublishMqtt(message: message, topic: "/ios/topic-rzv/peer2")
//            self.signalClient.send(sdp: sdp)
            
        }
    }
    
    @IBAction private func answerDidTap(_ sender: UIButton) {
        self.webRTCClient.answer { (localSdp) in
            self.hasLocalSdp = true
            let message = Message.sdp(SessionDescription(from: localSdp))
            self.encodeMessageAndPublishMqtt(message: message, topic: "/ios/topic-rzv/peer2")
//            self.signalClient.send(sdp: localSdp)
        }
    }
    
    @IBAction private func speakerDidTap(_ sender: UIButton) {
        if self.speakerOn {
            self.webRTCClient.speakerOff()
        }
        else {
            self.webRTCClient.speakerOn()
        }
        self.speakerOn = !self.speakerOn
    }
    
    @IBAction private func videoDidTap(_ sender: UIButton) {
        self.present(videoViewController, animated: true, completion: nil)
    }
    
    @IBAction private func muteDidTap(_ sender: UIButton) {
        self.mute = !self.mute
        if self.mute {
            self.webRTCClient.muteAudio()
        }
        else {
            self.webRTCClient.unmuteAudio()
        }
    }
    
    @IBAction func sendDataDidTap(_ sender: UIButton) {
        let alert = UIAlertController(title: "Send a message to the other peer",
                                      message: "This will be transferred over WebRTC data channel",
                                      preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Message to send"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak self, unowned alert] _ in
            guard let dataToSend = alert.textFields?.first?.text?.data(using: .utf8) else {
                return
            }
            self?.webRTCClient.sendData(dataToSend)
        }))
        self.present(alert, animated: true, completion: nil)
    }
   
    
    private func encodeMessageAndPublishMqtt(message: Message, topic: String) {
        do {
            
            let encodedMessage = try JSONEncoder().encode(message)
            let sdpByteArr = [UInt8](encodedMessage)
            let cocoaMqttMessage = CocoaMQTTMessage(topic: topic, payload: sdpByteArr)
            self.mqtt.publish(cocoaMqttMessage)
        } catch {
             debugPrint("Warning: Could not encode sdp: \(error)")
        }
    }
}

//extension MainViewController: SignalClientDelegate {
//    func signalClientDidConnect(_ signalClient: SignalingClient) {
//        self.signalingConnected = true
//    }
//
//    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
//        self.signalingConnected = false
//    }
//
//    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
//        print("Received remote sdp")
//        self.webRTCClient.set(remoteSdp: sdp) { (error) in
//            self.hasRemoteSdp = true
//        }
//    }
//
//    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
//        print("Received remote candidate")
////        self.remoteCandidateCount += 1
//        self.webRTCClient.set(remoteCandidate: candidate)
//    }
//}

extension MainViewController: WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("discovered local candidate")
        let message = Message.candidate(IceCandidate(from: candidate))
        self.encodeMessageAndPublishMqtt(message: message, topic: "/ios/topic-rzv/peer2")
//        self.localCandidateCount += 1
//        self.signalClient.send(candidate: candidate)
        
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        let textColor: UIColor
        switch state {
        case .connected, .completed:
            textColor = .green
            self.conversationOptionsStackView.isHidden = false
        case .disconnected:
            textColor = .orange
        case .failed, .closed:
            textColor = .red
        case .new, .checking, .count:
            textColor = .black
        @unknown default:
            textColor = .black
        }
        DispatchQueue.main.async {
            self.webRTCStatusLabel?.text = state.description.capitalized
            self.webRTCStatusLabel?.textColor = textColor
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        DispatchQueue.main.async {
            let message = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes)"
            let alert = UIAlertController(title: "Message from WebRTC", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension MainViewController: CocoaMQTTDelegate {
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("💚 mqtt did ping")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print("💚 mqtt did receive ping")
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        print("💚 mqtt did disconnect: \(err!.localizedDescription)")

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            self.mqttConnect()
        }
       
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("💚 mqtt did connect ack: \(ack.description)")
        if ack == .accept {
            let phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber")
            let topicName = "/ios/\(phoneNumber!)"
            mqtt.subscribe(topicName, qos: .qos1)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        
        print("💚 Did publish message: \(message.string!)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("💚 Did publish ack: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        print("💚 Did receive message: \(message.string!)")
        
        let decodedMessage: Message
        let encodedMessage = message.string!.data(using: .utf8)
        do {
            decodedMessage = try JSONDecoder().decode(Message.self, from: encodedMessage!)
        } catch {
            debugPrint("❤️ Could not decode incoming message: \(error)")
            return
        }
        
        switch  decodedMessage {
        case .candidate(let iceCandidate):
            print("Received remote candidate")
            self.webRTCClient.set(remoteCandidate: iceCandidate.rtcIceCandidate)
        case .sdp(let sessionDescription):
            print("Received remote sdp")
            self.webRTCClient.set(remoteSdp: sessionDescription.rtcSessionDescription) { (error) in
                self.hasRemoteSdp = true
            }
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {
        print("💚 Did subscribe topics: \(topics.joined(separator: ","))")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("💚 Did unsubscribe topic: \(topic)")
    }
    
    
}
