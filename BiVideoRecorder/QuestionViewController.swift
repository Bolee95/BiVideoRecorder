//
//  QuestionViewController.swift
//  VideoRecording
//
//  Created by Bogdan Ilic on 2/6/19.
//  Copyright © 2019 Bogdan Ilic. All rights reserved.
//

import UIKit

public class QuestionViewController: UIViewController {

    @IBOutlet weak var nextQuestionButton: UIButton!
    @IBOutlet weak var questionText: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    
    let questions = ["How old are you?", "What's your name?", "What's your favorite food?"]
    var counter = 0
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = 10
        backgroundView.alpha = 0.5
        questionText.text = questions.first
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.alpha = 0
        UIView.animate(withDuration: 1, animations: {
            self.view.alpha = 1
        })
    }
    
    @IBAction func nextQuestionPressed(_ sender: Any) {
        counter = (counter + 1) % questions.count
        questionText.text = questions[counter]
    }
}
