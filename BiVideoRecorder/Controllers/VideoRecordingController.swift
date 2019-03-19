//
//  ViewController.swift
//  VideoRecording
//
//  Created by Bogdan Ilic on 1/30/19.
//  Copyright © 2019 Bogdan Ilic. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

public class VideoRecordingController: UIViewController {
    
    //MARK: - Properties, Outlets and Variables
    
    var videoController = VideoController()
    var animateStop = false
    
    @IBOutlet weak var questionsContainerView: UIView!
    @IBOutlet weak var fleshToggleButton: UIButton!
    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var recordingButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var recordingRec: UIImageView!
    @IBOutlet weak var cameraChangeButton: UIButton!
    
    //MARK: - LifeCycle methods
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        videoController = VideoController()
        func configureCamera() {
            videoController.prepare(completionHandler: { (error) in
                if let error = error {
                    self.videoController.handleError(error: error)
                }
            })
            
            try? self.videoController.preparePreview(on: self.cameraPreviewView)
            
            NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        }
        
        configureCamera()
        videoController.delegate = self
        insertQuestionsController()
    }
    
    //MARK: - Controls actions
    
    @IBAction func fleshTogglePressed(_ sender: Any) {
        try? videoController.toggleFlesh()
    }
    
    @IBAction func cameraSwitchPressed(_ sender: UIButton) {
        try? videoController.switchCamera()
    }
    @IBAction func recordingButtonPressed(_ sender: Any) {
        try? videoController.startRecording()
        animateStop = false
        self.animateRec()
    }
    
    //MARK: - Transformations on orientation change observer
    
    @objc func orientationDidChange() {
        videoController.orientationChange()
    }
    
    func insertQuestionsController() {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "QuestionViewController")
        installViewController(vc, inContainerView: questionsContainerView)
    }
}

//MARK: - Error handling method and screen controls changes methods

extension VideoRecordingController: VideoRecorderDelegate {
    
    func rotateControls(angle: Double) {
        UIView.animate(withDuration: 0.6, animations: {
            self.fleshToggleButton.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
            self.cameraChangeButton.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
        })
    }
    
    func showErrorText(title: String, text: String) {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
  
    func timerUpdate(label: String) {
        DispatchQueue.main.async {
            self.timerLabel.text = label
        }
    }
    
    func playRecordedData(url: URL) {
        animateStop = true
        recordingRec.alpha = 0
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PreviewVideoController") as! PreviewVideoController
        vc.videoURL = url
        present(vc, animated: true, completion: nil)
    }
    
    func timerStop() {
        self.timerLabel.text = "00:00:00"
    }
    
    private func installViewController(_ viewController: UIViewController?, inContainerView containerView: UIView) {
        if let viewController = viewController {
            viewController.view.isHidden = true
            addChild(viewController)
            viewController.view.frame = containerView.bounds
            containerView.addSubview(viewController.view)
            viewController.didMove(toParent: self)
            viewController.view.isHidden = false
        }
    }
    
    func animateRec() {
        UIView.animate(withDuration: 1, animations: {
            self.recordingRec.alpha = 1
        }, completion: { done in
            UIView.animate(withDuration: 1, animations: {
                self.recordingRec.alpha = 0
            }, completion: { done in
                if !self.animateStop {
                    self.animateRec()
                }
            })
        })
    }
    
    public static func presentFirstViewControllerOn(_ viewController:UIViewController) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Video", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "VideoRecordingController") as! VideoRecordingController
        viewController.present(nextViewController, animated:true, completion:nil)
    }
    
}
