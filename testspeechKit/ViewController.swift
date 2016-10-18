//
//  ViewController.swift
//  testspeechKit
//
//  Created by zero on 16/10/18.
//  Copyright © 2016年 zero. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {

    weak var label: UILabel?
    weak var button: UIButton?
    weak var textView: UITextView?
    
    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    
    let speechRecoginzer = SFSpeechRecognizer(locale: Locale.init(identifier: "zh-CN"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSubview()
        self.setupSpeech()
    }

    func setupSubview() {
        self.view.backgroundColor = UIColor.white
        
        label = UILabel().then {
            self.view.addSubview($0)
            $0.anchorToEdge(.top, padding: 20, width: screenWidth-20, height: 120)
            $0.text = "请问需要帮忙吗？"
            $0.textAlignment = .center
            $0.font = UIFont.systemFont(ofSize: 50)
            $0.numberOfLines = 2
        }
        
        button = UIButton().then {
            self.view.addSubview($0)
            $0.addTarget(self, action: #selector(ViewController.buttonTap), for: .touchUpInside)
            $0.setTitle("请撮一下", for: .normal)
            $0.backgroundColor = UIColor.red
            $0.anchorToEdge(.bottom, padding: 10, width: screenWidth-20, height: 30)
        }
        
        textView = UITextView().then {
            self.view.addSubview($0)
            $0.anchorInCenter(width: screenWidth-20, height: 50)
            $0.text = "有什么事就说..."
            $0.backgroundColor = UIColor.lightGray
        }
    }
    
    func buttonTap() {
        print("被撮了一下")
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            button?.isEnabled = false
            button?.setTitle("start recording", for: .normal)
        }else{
            startRecording()
            button?.setTitle("stop recording", for: .normal)
        }
        
    }
    
    func setupSpeech() {
        speechRecoginzer?.delegate = self
        SFSpeechRecognizer.requestAuthorization { (status) in
            
            var buttonEnable = false
            var autoStatusDescription = ""
            
            switch status {
            case .authorized:
                buttonEnable = true
                autoStatusDescription = "请撮一下"
            case .denied:
                buttonEnable = false
                autoStatusDescription = "授权被拒"
            case .notDetermined:
                buttonEnable = false
                autoStatusDescription = "尚未授权"
            case .restricted:
                buttonEnable = false
                autoStatusDescription = "授权受限"
            }
            
            OperationQueue.main.addOperation({
                self.button?.isEnabled = buttonEnable
                self.button?.setTitle(autoStatusDescription, for: .normal)
            })
        }
    }

    
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        recognitionTask = speechRecoginzer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            if result != nil {
                self.textView?.text = result?.bestTranscription.formattedString
                isFinal = result!.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.button?.isEnabled = true
            }
        })
        textView?.text = "say something, i am listening!"
    }

    
    
}

extension ViewController: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.button?.isEnabled = true
        }else{
            self.button?.isEnabled = false
        }
    }
}

