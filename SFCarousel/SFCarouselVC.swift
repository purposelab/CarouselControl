//
//  SFCarouselVC.swift
//  SFCarousel
//
//  Created by Pavel Tikhonenko on 19/04/16.
//  Copyright © 2016 Pavel Tikhonenko. All rights reserved.
//

import UIKit

protocol SFCarouselVCDelegate: class
{
    
}

class SFCarouselVC: UIViewController
{
    var carouselView: SFCarouselView!
    weak var delegate: SFCarouselVCDelegate?
    
    //MARK: - Public -
    
    func reloadData()
    {
        carouselView.reloadData()
    }
    
    //MARK: - Internal & Private -
    
    internal func initView()
    {
        initializeCarouselView()
    }
    
    //MARK: - Life cycle -
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        initView()
    }
}

extension SFCarouselVC: SFCarouselViewDelegate
{
    private func initializeCarouselView()
    {
        carouselView = SFCarouselView(frame: view.bounds)
        registerCarouselCells(carouselView)
        carouselView.delegate = self
        carouselView.backgroundColor = UIColor.clearColor()
        carouselView.resetContentOffset()
        view.addSubview(carouselView)
        
        
    }
 
    internal func registerCarouselCells(carouselView: SFCarouselView)
    {

    }
    
    //MARK: - SFCarouselViewDelegate -
    
    func carouselViewNumberOfItems(carouselView: SFCarouselView) -> Int
    {
        return 0
    }
    
    func carouselView(carouselView: SFCarouselView, cellForItemAtIndex index: Int) -> SFCarouselViewCell
    {
        return SFCarouselViewCell()
    }
}
 