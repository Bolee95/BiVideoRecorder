//
//  Stopwatch.swift
//  VideoRecording
//
//  Created by Bogdan Ilic on 2/4/19.
//  Copyright © 2019 Bogdan Ilic. All rights reserved.
//

import Foundation

public class Stopwatch {
    
    var counter = 0
    var timer = Timer()
    var isCounting = false
    var labelString : String?
    weak var delegate : StopwatchDelegate?
    
    public init() {
        labelString = "00:00:00"
    }
    
    public func startTimer() {
        if isCounting {
            return
        }
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(inclement), userInfo: nil, repeats: true)
    }
    
    @objc public func inclement() {
        counter += 1
        DispatchQueue.global().async {
            let sec = self.counter % 60
            let secStr = (sec / 10 > 0) ? "\(sec)" : "0\(sec)"
            let min = (self.counter / 60) % 60
            let minStr = (min / 10 > 0) ? "\(min)" : "0\(min)"
            let hour = self.counter / 3600
            self.labelString = "0\(hour):\(minStr):\(secStr)"
            self.delegate?.updateStopwatchLabel(label: self.labelString!)
        }
    }
    
    public func stopTimer() {
        isCounting = false
        counter = 0
        timer.invalidate()
    }
}
