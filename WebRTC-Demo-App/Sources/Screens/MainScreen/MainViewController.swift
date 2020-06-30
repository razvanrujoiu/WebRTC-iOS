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
import PKHUD
import CryptoSwift

class MainViewController: UIViewController {

    private let config = Config.default
//    private let signalClient: SignalingClient
    private var webRTCClient: WebRTCClient
    private var remotePhoneNumber: String?
    private lazy var videoViewController = VideoViewController(webRTCClient: self.webRTCClient)
    
    @IBOutlet private weak var speakerButton: UIButton?
    @IBOutlet private weak var signalingStatusLabel: UILabel?
    @IBOutlet private weak var localSdpStatusLabel: UILabel?
    @IBOutlet private weak var remoteSdpStatusLabel: UILabel?
    @IBOutlet private weak var muteButton: UIButton?
    @IBOutlet private weak var webRTCStatusLabel: UILabel?
    @IBOutlet weak var answerButton: UIButton!
    
    @IBOutlet weak var conversationOptionsStackView: UIStackView!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    var mqtt: CocoaMQTT!
    
    private var connectionState: RTCIceConnectionState = .new {
        didSet {
            DispatchQueue.main.async {
                switch self.connectionState {
                case .connected, .completed:
                    self.conversationOptionsStackView.isHidden = false
                case .closed, .disconnected, .failed:
                    self.webRTCClient.endCall()
                    self.conversationOptionsStackView.isHidden = true
                    self.remotePhoneNumber = nil
                    self.hasRemoteSdp = false
                    self.hasLocalSdp = false
                case .checking, .new, .count:
                    print("❤️ count, checking")
                @unknown default: break
                    
                }
            }
        }
    }
    
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
    
    private var hasRemoteSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.remoteSdpStatusLabel?.text = self.hasRemoteSdp ? "✅" : "❌"
                if self.hasRemoteSdp {
                    self.answerButton.isHidden = false
                } else {
                    self.answerButton.isHidden = true
                }
                
            }
        }
    }
    
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
        
        guard let phoneNumber = phoneNumberTextField.text, RUtility.isValidPhone(phone: phoneNumber) else {
            return
        }
        self.remotePhoneNumber = phoneNumber
        if !webRTCClient.isRtcPeerConnectionAlive() {
            
            self.webRTCClient = WebRTCClient(iceServers: self.config.webRTCIceServers)
        }
        
        self.webRTCClient.offer { (sdp) in
            self.hasLocalSdp = true
            let srcPhoneNumber = UserDefaults.standard.string(forKey: "phoneNumber")
            let sessionDescription = SessionDescription(from: sdp, srcPhoneNumber: srcPhoneNumber!)
            let message = Message.sdp(sessionDescription)
            self.encodeMessageAndPublishMqtt(message: message, topic: "/\(self.remotePhoneNumber!)")
            
        }
    }
    
    @IBAction private func answerDidTap(_ sender: UIButton) {
        
        if !webRTCClient.isRtcPeerConnectionAlive() {
            self.webRTCClient = WebRTCClient(iceServers: self.config.webRTCIceServers)
        }
        
        self.webRTCClient.answer { (localSdp) in
            self.hasLocalSdp = true
            let srcPhoneNumber = UserDefaults.standard.string(forKey: "phoneNumber")
            let sessionDescription = SessionDescription(from: localSdp, srcPhoneNumber: srcPhoneNumber!)
            let message = Message.sdp(sessionDescription)
            self.encodeMessageAndPublishMqtt(message: message, topic: "/\(self.remotePhoneNumber!)")
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
            let cocoaMqttMessage: CocoaMQTTMessage!
            if RzvConstants.useEncryption {
                let encryptedMessage = CryptoUtil.encryptAES128(inputContent: sdpByteArr, key: topic)
                cocoaMqttMessage = CocoaMQTTMessage(topic: topic, payload: encryptedMessage)
            } else {
                cocoaMqttMessage = CocoaMQTTMessage(topic: topic, payload: sdpByteArr)
            }
            
            self.mqtt.publish(cocoaMqttMessage)
        } catch {
             debugPrint("Warning: Could not encode sdp: \(error)")
        }
    }
    
    @IBAction func didTapLogoutBtn(_ sender: UIButton) {
        UserDefaults.standard.removeObject(forKey: "phoneNumber")
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapEndCallBtn(_ sender: UIButton) {
        // TODO must modify end conne
        self.webRTCClient.endCall()
        self.remotePhoneNumber = nil
        self.hasLocalSdp = false
        self.hasRemoteSdp = false
    }
    
}


extension MainViewController: WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("discovered local candidate")
        let srcPhoneNumber = UserDefaults.standard.string(forKey: "phoneNumber")
        let iceCandidate = IceCandidate(from: candidate, srcPhoneNumber: srcPhoneNumber!)
        let message = Message.candidate(iceCandidate)
        self.encodeMessageAndPublishMqtt(message: message, topic: "/\(self.remotePhoneNumber!)")
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        let textColor: UIColor
        self.connectionState = state
        switch state {
        case .connected, .completed:
            textColor = .green
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
            let topicName = "/\(phoneNumber!)"
            mqtt.subscribe(topicName, qos: .qos1)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        
//        print("💚 Did publish message: \(message.string!)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("💚 Did publish ack: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
//        print("💚 Did receive message: \(message.string!)")
        
        if !webRTCClient.isRtcPeerConnectionAlive() {
            self.webRTCClient = WebRTCClient(iceServers: config.webRTCIceServers)
        }
        let encodedMessage: Data!
        let decodedMessage: Message
        if RzvConstants.useEncryption {
            let decryptionKey = UserDefaults.standard.string(forKey: "phoneNumber")
            let decryptedMessage =  CryptoUtil.decryptAES128(inputContent: message.payload, key: "/\(decryptionKey!)")
            encodedMessage = Data(bytes: decryptedMessage, count: decryptedMessage.count)
        } else {
            encodedMessage = message.string!.data(using: .utf8)
        }
        do {
            decodedMessage = try JSONDecoder().decode(Message.self, from: encodedMessage)
        } catch {
            debugPrint("❤️ Could not decode incoming message: \(error)")
            return
        }
    
        switch  decodedMessage {
        case .candidate(let iceCandidate):
            print("Received remote candidate")
            self.remotePhoneNumber = iceCandidate.srcPhoneNumber
            self.webRTCClient.set(remoteCandidate: iceCandidate.rtcIceCandidate)
        case .sdp(let sessionDescription):
            print("Received remote sdp")
            self.remotePhoneNumber = sessionDescription.srcPhoneNumber
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

