//
//  GLFRadioContentCell.swift
//  SFCarousel
//
//  Created by Pavel Tikhonenko on 20/04/16.
//  Copyright © 2016 Pavel Tikhonenko. All rights reserved.
//

import UIKit

class GLFRadioContentCell: GLFContentCell
{
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        label.text = "RADIO"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}