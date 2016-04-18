//
//  ViewController.swift
//  SFCarousel
//
//  Created by Pavel Tikhonenko on 08/02/16.
//  Copyright © 2016 Pavel Tikhonenko. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SFCarouselViewDelegate
{

    var carousel: SFCarouselView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        carousel = SFCarouselView(frame: view.bounds)
        carousel.registerClass(SFCarouselViewCell.self, forCellReuseIdentifier: "Cell")
        carousel.delegate = self
        view.addSubview(carousel)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }


    func carouselViewNumberOfItems(carouselView: SFCarouselView) -> Int
    {
        return 30
    }
    
    func carouselView(carouselView: SFCarouselView, cellForItemAtIndex index: Int) -> SFCarouselViewCell
    {
        if let v = carouselView.dequeueReusableCellWithIdentifier("Cell")
        {
            v.backgroundColor = UIColor.redColor()
            v.label.text = String(index)
            return v
        }
        
        return SFCarouselViewCell()
    }
    
    func carouselViewMenuCell(carouselView: SFCarouselView) -> SFCarouselViewMenuCell
    {
        let menuCell = SFCarouselViewMenuCell()
        menuCell.backgroundColor = UIColor.blueColor()
        menuCell.label.text = "Menu"
        return menuCell
    }
    
    func carouselViewHasMenu(carouselView: SFCarouselView) -> Bool
    {
        return true
    }
}

