//
//  TouchView.swift
//  BPM Counter
//
//  Created by Benjamin Ludwig on 15.01.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit

@objc protocol TouchViewDelegate {
    
    func touchViewTouchBegan(touchView: TouchView)
    func touchViewTouchEnded(touchView: TouchView)
    
}

class TouchView: UIView {
    
    @IBOutlet weak var delegate: TouchViewDelegate?

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesBegan(touches, with: event)
        delegate?.touchViewTouchBegan(touchView: self)
        
//        let generator = UIImpactFeedbackGenerator(style: .light)
//        generator.impactOccurred()
        
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesEnded(touches, with: event)
        delegate?.touchViewTouchEnded(touchView: self)
        
    }
    

}
