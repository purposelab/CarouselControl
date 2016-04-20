//
//  GLFBottomContentCell.swift
//  SFCarousel
//
//  Created by Pavel Tikhonenko on 20/04/16.
//  Copyright © 2016 Pavel Tikhonenko. All rights reserved.
//

import UIKit

class GLFBottomContentCell: GLFContentCell
{
    var contentScrollView: UIScrollView!
    var tempBottomView: UILabel!
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Private & Internal -
    
    private func initView()
    {
        contentScrollView = GLFBottomContentScrollView(frame: bounds)
        contentScrollView.pagingEnabled = true
        contentScrollView.bounces = false
        addSubview(contentScrollView)
        updateScrollViewSize()
        
        tempBottomView = UILabel(frame: bounds)
        tempBottomView.text = "Bottom View"
        tempBottomView.textAlignment = .Center
        tempBottomView.backgroundColor = UIColor.grayColor()
        contentScrollView.addSubview(tempBottomView)
    }
    
    private func updateScrollViewSize()
    {
        contentScrollView.frame = bounds
        
        var contentSize = bounds.size
        contentSize.height *= 2
        contentScrollView.contentSize = contentSize
        
        
    }
    
    private func updateBottomViewSize()
    {
        var bottomViewFrame = bounds
        bottomViewFrame.origin.y = bounds.height
        tempBottomView.frame = bottomViewFrame
    }
    
    override func prepareForReuse()
    {
        super.prepareForReuse()
        
        contentScrollView.contentOffset = CGPointZero
    }
    //MARK: - Life cycle -
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        updateScrollViewSize()
        updateBottomViewSize()
    }
}

class GLFBottomContentScrollView: UIScrollView
{
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if contentOffset.y != 0 && otherGestureRecognizer != self
        {
            return false
        }
        
        return true
    }
}