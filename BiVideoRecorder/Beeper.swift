//
//  Beeper.swift
//  VideoRecording
//
//  Created by Bogdan Ilic on 2/1/19.
//  Copyright © 2019 Bogdan Ilic. All rights reserved.
//

import Foundation
import AVFoundation

public class Beeper {
    var audioPlayer = AVAudioPlayer()
    
    func playSound(_ sound: BeeperSounds, completionHandler: ()->()) {
        let beepSound = URL(fileURLWithPath: Bundle.main.path(forResource: sound.rawValue, ofType: ".wav")!)
        audioPlayer = try! AVAudioPlayer(contentsOf: beepSound)
        audioPlayer.prepareToPlay()
        audioPlayer.play()
        completionHandler()
    }
}

enum BeeperSounds : String {
    case recordStart = "recordStart"
    case recordStop = "recordStop"
    
}
