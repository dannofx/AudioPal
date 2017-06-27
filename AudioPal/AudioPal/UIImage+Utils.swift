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
}
