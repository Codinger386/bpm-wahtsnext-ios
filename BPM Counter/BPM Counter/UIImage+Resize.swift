//
//  UIImage+Resize.swift
//  eLIZA2
//
//  Created by Benjamin Ludwig on 14.12.16.
//  Copyright © 2016 me for mobile UG. All rights reserved.
//

import UIKit

public extension UIImage {
    
    func resizedImage(minEdgeLength: CGFloat) -> UIImage {
        
        var scale: CGFloat = 1
        if self.size.width > self.size.height {
            scale = minEdgeLength / self.size.height
            let newWidth = self.size.width * scale
            UIGraphicsBeginImageContext(CGSize(width: newWidth, height: minEdgeLength))
            let context = UIGraphicsGetCurrentContext()
            context!.interpolationQuality = .high
            self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: minEdgeLength))
            
        } else {
            scale = minEdgeLength / self.size.width
            let newHeight = self.size.height * scale
            UIGraphicsBeginImageContext(CGSize(width: minEdgeLength, height: newHeight))
            let context = UIGraphicsGetCurrentContext()
            context!.interpolationQuality = .high
            self.draw(in: CGRect(x: 0, y: 0, width: minEdgeLength, height: newHeight))
            
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
}
