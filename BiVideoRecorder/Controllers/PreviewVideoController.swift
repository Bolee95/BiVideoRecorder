//
//  PreviewVideoController.swift
//  VideoRecording
//
//  Created by Bogdan Ilic on 2/5/19.
//  Copyright © 2019 Bogdan Ilic. All rights reserved.
//

import UIKit
import AVKit

public class PreviewVideoController: UIViewController {

    @IBOutlet var videoPreviewView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var useVideoButton: UIButton!
    
    var videoURL : URL?
    var playerLayer = AVPlayerLayer()
    var player = AVPlayer()
    
    override public func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override public func viewWillAppear(_ animated: Bool) {
        
        guard let videoURL = self.videoURL else { return }
        player = AVPlayer(url: videoURL)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoPreviewView.bounds
        self.videoPreviewView.layer.addSublayer(playerLayer)
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        playerLayer.player?.seek(to: CMTime.zero)
        playerLayer.player?.play()
    }
    
    @IBAction func retakeVideoPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override public func viewDidLayoutSubviews() {
        playerLayer.frame = view.bounds
    }
    
}
