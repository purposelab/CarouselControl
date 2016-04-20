//
//  GLFContentVC.swift
//  SFCarousel
//
//  Created by Pavel Tikhonenko on 20/04/16.
//  Copyright © 2016 Pavel Tikhonenko. All rights reserved.
//

import UIKit

class GLFContentVC: UIViewController
{
    internal var currentContentView: GLFContentCell!
    
    init(contentView: GLFContentCell)
    {
        self.currentContentView = contentView
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Internal -
    
    internal func initView()
    {
        
    }
    
    //MARK: - Life Cycle - 
    
    override func loadView()
    {
        self.view = currentContentView
    }
    
    override func viewDidLoad()
    {
        initView()
    }
}
