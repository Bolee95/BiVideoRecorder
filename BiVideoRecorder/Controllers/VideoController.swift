//
//  VideoController.swift
//  VideoRecording
//
//  Created by Bogdan Ilic on 1/30/19.
//  Copyright © 2019 Bogdan Ilic. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import MobileCoreServices

public class VideoController : NSObject {
    
    //MARK: - Properties and Variables
    
    weak var delegate: VideoRecorderDelegate?
    // method 1
    var captureSession: AVCaptureSession?
    
    // method 2
    var cameraPosition: CameraPosition?
    var frontCameraInput: AVCaptureDeviceInput?
    var backCameraInput: AVCaptureDeviceInput?
    var microphoneInput: AVCaptureDeviceInput?
    
    // method 3
    var frontCamera: AVCaptureDevice?
    var backCamera: AVCaptureDevice?
    var microphone: AVCaptureDevice?
    
    // method 4
    var videoOutput: AVCaptureMovieFileOutput
    //var microphone: AVCaptureDeviceInput?
    
    // preview var
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var outputURL: URL!
    
    var beeper = Beeper()
    var timer = Stopwatch()
    
    var fleshState = false //off state
    
    required override init() {
        videoOutput = AVCaptureMovieFileOutput()
        super.init()
        timer.delegate = self
    }
    
    //MARK: - Main setup method for recorder
    
    func prepare(completionHandler: @escaping (VideoControllerError?) -> Void) {
        do {
            try checkCaptureAuthorization()
            createCaptureSession()
            try configureCaptureDevices()
            try configureDeviceInputs()
            try configureVideoOutput()
        }
        catch {
            DispatchQueue.global().async {
                completionHandler(error as? VideoControllerError)
            }
            return
        }
        DispatchQueue.main.async {
            completionHandler(nil)
        }
    }
    
    //MARK: - Setup methods
    
    // method 1
    func createCaptureSession() {
        self.captureSession = AVCaptureSession()
        self.captureSession?.beginConfiguration()
        if ((self.captureSession?.canSetSessionPreset(.high))!) { self.captureSession?.sessionPreset = .high}
        self.captureSession?.commitConfiguration()
    }
    
    // method 2
    func configureCaptureDevices() throws {
        let deviceDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: [ .builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        if deviceDiscovery.devices.count == 0 {
            throw VideoControllerError.noCameraAvailable
        }
        for camera in deviceDiscovery.devices {
            if camera.position == .front {
                self.frontCamera = camera
            }
            else if camera.position == .back{
                self.backCamera = camera
            }
            try camera.lockForConfiguration()
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            if camera.isSmoothAutoFocusSupported {
                camera.isSmoothAutoFocusEnabled = true
            }
            camera.unlockForConfiguration()
        }
        microphone = AVCaptureDevice.default(for: .audio)
    }
    
    // method 3
    func configureDeviceInputs() throws {
        guard let captureSession = self.captureSession else { throw VideoControllerError.captureSessionIsMissing }
        if let backCamera = self.backCamera {
            self.backCameraInput = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(self.backCameraInput!) { captureSession.addInput(self.backCameraInput!)}
            self.cameraPosition = .back
        }
        else if let frontCamera = self.frontCamera {
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(self.frontCameraInput!) { captureSession.addInput(self.frontCameraInput!)}
        }
        else {
            throw VideoControllerError.noCameraAvailable
        }
        if let microphone = self.microphone {
            self.microphoneInput = try AVCaptureDeviceInput(device: microphone)
            if captureSession.canAddInput(self.microphoneInput!) {
                captureSession.addInput(self.microphoneInput!)
            }
        }
        else { throw VideoControllerError.noMicrophoneAvailable }
        
        
    }
    
    // method 4
    func configureVideoOutput() throws {
        guard let captureSession = self.captureSession else { throw VideoControllerError.captureSessionIsMissing}
        self.videoOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(self.videoOutput) { captureSession.addOutput(self.videoOutput) }
        captureSession.startRunning()
    }
    
    func checkCaptureAuthorization() throws {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break // The user has previously granted access to the camera.
        case .notDetermined:  // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                }
                else {
                    //throw VideoControllerError.cameraAccessDenied
                }
            }
            break
        case .denied: // The user has previously denied access.
            throw VideoControllerError.cameraAccessDenied
        case .restricted: // The user can't grant access due to restrictions.
            throw VideoControllerError.cameraAccessRestricted
        }
    }
    
    //MARK: - Recording and video preview methods
    
    func getTempURL() -> URL {
        let cacheDir = NSTemporaryDirectory()
        return URL(fileURLWithPath: cacheDir).appendingPathComponent(NSUUID().uuidString + ".mov")
    }
    
    func startRecording() throws {
        if videoOutput.isRecording == false {
            guard let connection = videoOutput.connection(with: .video) else { throw VideoControllerError.connectionFail }
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = getCameraOrientation()
            }
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }
            beeper.playSound(.recordStart) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 , execute: {
                    self.outputURL = self.getTempURL()
                    self.videoOutput.startRecording(to: self.outputURL, recordingDelegate: self)
                    self.timer.startTimer()
                })
                
            }
        }
        else {
            stopRecording()
            timer.stopTimer()
            beeper.playSound(.recordStart) {}
        }
    }
    
    func stopRecording() {
        if videoOutput.isRecording == true {
            videoOutput.stopRecording()
            self.delegate?.timerStop()
        }
    }
    
    func preparePreview(on view: UIView) throws {
        guard let captureSession = self.captureSession else { throw VideoControllerError.captureSessionIsMissing}
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.videoPreviewLayer?.connection?.videoOrientation = getCameraOrientation()
        if (self.videoPreviewLayer?.connection?.isVideoStabilizationSupported)! {
            self.videoPreviewLayer?.connection?.preferredVideoStabilizationMode = .auto
        }
        view.layer.insertSublayer(self.videoPreviewLayer!, at: 0)
        self.videoPreviewLayer?.frame = view.bounds
    }
    
    func updatePreview(on view: UIView) throws {
        self.videoPreviewLayer?.frame = view.bounds
        self.videoPreviewLayer?.connection?.videoOrientation = getCameraOrientation()
    }
    
    //MARK: - Camera switching and Flesh methods
    
    func toggleFlesh() throws  {
        guard let cameraPosition = self.cameraPosition else {
            throw VideoControllerError.noCameraAvailable
        }
        switch cameraPosition {
        case .back:
            if (backCamera?.hasTorch)! {
                try backCamera?.lockForConfiguration()
                backCamera?.torchMode = (fleshState ? .off : .on)
                backCamera?.unlockForConfiguration()
            }
            break
        case .front:
            if (frontCamera?.hasTorch)! {
                try frontCamera?.lockForConfiguration()
                frontCamera?.torchMode = (fleshState ? .off : .on)
                frontCamera?.unlockForConfiguration()
            }
        case .dual:
            break
        }
        self.fleshState = !fleshState
    }
    
    func switchCamera() throws {
        guard let currentCameraPosition = self.cameraPosition, let captureSession = self.captureSession, captureSession.isRunning else {
            throw VideoControllerError.cameraPositionNotSet
        }
        captureSession.beginConfiguration()
        switch currentCameraPosition {
        case .front:
            try switchToBackCamera()
        case .back:
            try switchToFrontCamera()
        default:
            break
        }
        captureSession.commitConfiguration()
    }
    
    func switchToFrontCamera() throws {
        guard let inputs = captureSession?.inputs, let backCameraInput  = self.backCameraInput, inputs.contains(backCameraInput), let frontCamera = self.frontCamera else { throw VideoControllerError.captureSessionIsMissing }
        self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
        captureSession?.removeInput(backCameraInput)
        if (captureSession?.canAddInput(frontCameraInput!))! {
            captureSession?.addInput(frontCameraInput!)
            cameraPosition = .front
        }
        else { throw VideoControllerError.invalidOperation }
    }
    
    func switchToBackCamera() throws {
        guard let inputs = captureSession?.inputs, let frontCameraInput = self.frontCameraInput, inputs.contains(frontCameraInput), let backCamera = self.backCamera else { throw VideoControllerError.captureSessionIsMissing }
        self.backCameraInput = try AVCaptureDeviceInput(device: backCamera)
        captureSession?.removeInput(frontCameraInput)
        if ((captureSession?.canAddInput(backCameraInput!))!) {
            captureSession?.addInput(backCameraInput!)
            cameraPosition = .back
        }
        else { throw VideoControllerError.invalidOperation }
    }
    
    //MARK: - Orientation changes methods
    
    func getCameraOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeRight
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        default:
            return AVCaptureVideoOrientation.portrait
        }
    }
    
    func orientationChange() {
        
        var rotationAngle = 0.0
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            rotationAngle = Double.pi / 2
        case .landscapeRight:
            rotationAngle = -Double.pi / 2
        case .portraitUpsideDown:
            rotationAngle = 0
        default:
            break
        }
        self.delegate?.rotateControls(angle: rotationAngle)
    }
}

//MARK: - AVFoundation video recording delegate methods implementation

extension VideoController : AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            delegate?.playRecordedData(url: outputFileURL)
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
    }
}

//MARK: - Enums for errors and camera position

enum VideoControllerError: Swift.Error {
    case captureSessionAlreadyRunning
    case captureSessionIsMissing
    case inputsAreInvalid
    case invalidOperation
    case noCameraAvailable
    case noMicrophoneAvailable
    case cameraPositionNotSet
    case connectionFail
    case cameraAccessDenied
    case cameraAccessRestricted
    case unknown
}

enum CameraPosition {
    case back
    case front
    case dual
}

//MARK: - Stopwatch delegate methods implementation

extension VideoController: StopwatchDelegate {
    func updateStopwatchLabel(label: String) {
        self.delegate?.timerUpdate(label: label)
    }
}

//MARK: - Error handling function work

extension VideoController {
    func handleError(error : VideoControllerError) {
        var errorText = ""
        
        switch error {
        case .cameraPositionNotSet:
            errorText = "Camera position is currently not set."
        case .captureSessionAlreadyRunning:
            errorText = "Camera session is already running."
        case .captureSessionIsMissing:
            errorText = "Camera session is missing..."
        case .connectionFail:
            errorText = "Connection to devices failed."
        case .inputsAreInvalid:
            errorText = "Input devices are invalid."
        case .invalidOperation:
            errorText = "Invalid operation."
        case .noCameraAvailable:
            errorText = "No camera is currently available."
        case .noMicrophoneAvailable:
            errorText = "No microphone device is currently available."
        case .cameraAccessDenied:
            errorText = "Access to camera has been denied."
        case .cameraAccessRestricted:
            errorText = "Access to camera is restricted."
        case .unknown:
            errorText = "Unknown error occured."
        }
        self.delegate?.showErrorText(title: "Error", text: errorText)
    }
}

