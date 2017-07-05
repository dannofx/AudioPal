//
//  UIImage+Utils.swift
//  AudioPal
//
//  Created by Danno on 6/27/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

extension UIImage {
    class func imageWithColor(color: UIColor, height: CGFloat) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    class func imageWithColorBars(_ bars: [(color: UIColor, height: CGFloat)], totalHeight: CGFloat) -> UIImage {
        let totalRect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 40.0)
        var currentY: CGFloat = 0.0
        UIGraphicsBeginImageContextWithOptions(totalRect.size, false, 0.0)
        
        for (color, height) in bars {
            let rect = CGRect(x: 0.0, y: currentY, width: 1.0, height: height)
            color.setFill()
            UIRectFill(rect)
            currentY += height
            if currentY > totalHeight {
                break
            }
        }
        
        let image : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    
    class func imageWithColor3(color: UIColor, height: CGFloat) -> UIImage {
        let totalRect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 20.0)
        UIGraphicsBeginImageContextWithOptions(totalRect.size, false, 0.0)
        
        var bars = [(color: UIColor, height: CGFloat)]()
        bars.append((UIColor.blue, 10.0))
        bars.append((UIColor.purple, 10.0))
        
        var currentY: CGFloat = 0.0
        for (colorrr, height) in bars {
            let subRect = CGRect(x: 0.0, y: currentY, width: 1.0, height: height)
            colorrr.setFill()
            UIRectFill(subRect)
            currentY += height
        }
        

        let image : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
