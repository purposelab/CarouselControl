//
//  SFCarouselViewCell.swift
//  SFCarousel
//
//  Created by Pavel Tikhonenko on 9/02/16.
//  Copyright © 2016 Pavel Tikhonenko. All rights reserved.
//

import UIKit

//MARK: - Item view -

@objc class SFCarouselViewCell: UIView
{
    var reuseIdentifier: String?
    
    var contentView: UIView!
    var backgroundView: UIView?
    
    
    var index: Int {
        return tag
    }
    
    var preventFastModeTransition: Bool {
        return false
    }
    
    var label: UILabel = UILabel()
    
    override var frame: CGRect {
        didSet {
            layoutIfNeeded()
        }
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        label.textAlignment = .Center
        label.font = UIFont.systemFontOfSize(30)
        label.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse()
    {
        
    }
    
    func containerDidScroll(offset: CGFloat)
    {
        
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()

    }
    
    override func didMoveToSuperview()
    {
        hidden = superview == nil
    }
}

@objc class SFCarouselViewMenuCell: SFCarouselViewCell
{
    override var preventFastModeTransition: Bool {
        return true
    }
}

@objc class SFCarouselViewTransitionCell: SFCarouselViewCell
{
    override var preventFastModeTransition: Bool {
        return true
    }
}

func viewFromNib(nibName: String, atIdx idx:Int) -> UIView?
{
    let view =  NSBundle.mainBundle().loadNibNamed(nibName, owner: nil, options: nil)[idx] as! UIView
    return view
}