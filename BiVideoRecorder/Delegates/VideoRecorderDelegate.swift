//
//  VideoRecorderDelegate.swift
//  VideoRecording
//
//  Created by Bogdan Ilic on 2/1/19.
//  Copyright © 2019 Bogdan Ilic. All rights reserved.
//

import Foundation


protocol VideoRecorderDelegate: class {
    
    /** Delegate method that's being called when recorded data URL should be passed to main controller. */
    func playRecordedData(url: URL)
    func timerUpdate(label: String)
    func timerStop()
    func showErrorText(title: String, text: String)
    func rotateControls(angle: Double)
}
