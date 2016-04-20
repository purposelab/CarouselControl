//
//  GLFMainViewController.swift
//  SFCarousel
//
//  Created by Pavel Tikhonenko on 20/04/16.
//  Copyright © 2016 Pavel Tikhonenko. All rights reserved.
//

import UIKit

private var mockData = [GLFContentItemDTO(isRadio: false), GLFContentItemDTO(isRadio: false), GLFContentItemDTO(isRadio: false), GLFContentItemDTO(isRadio: false), GLFContentItemDTO(isRadio: false), GLFContentItemDTO(isRadio: true), GLFContentItemDTO(isRadio: false), GLFContentItemDTO(isRadio: false)]

class GLFMainViewController: SFCarouselVC
{
    
    
    private var contentControllers: [GLFContentCell: GLFContentVC] = [:]
    //MARK: - Private & Internal -
    
    override func initView()
    {
        super.initView()
    }
    
    private func presentContentCellWithinViewController(cell: GLFContentCell, data: GLFContentItemDTO)
    {
        let vc = contentViewController(cell, data: data)
        self.addChildViewController(vc)
        vc.willMoveToParentViewController(self)
        vc.view.frame = cell.frame
        contentControllers[cell] = vc
    }
    
    private func contentViewController(cell: GLFContentCell, data: GLFContentItemDTO) -> GLFContentVC
    {
        if let vc = contentControllers[cell]
        {
            return vc
        }
        
        return GLFContentVC(contentView: cell)
    }
    
    private func contentViewControllerByCell(cell: GLFContentCell) -> GLFContentVC?
    {
        return contentControllers[cell]
    }
    
    //MARK: - Life Cycle -
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
}

extension GLFMainViewController
{
    override func registerCarouselCells(carouselView: SFCarouselView)
    {
        carouselView.registerClass(GLFBottomContentCell.self, forCellReuseIdentifier: "GLFBottomContentCell")
        carouselView.registerClass(GLFRadioContentCell.self, forCellReuseIdentifier: "GLFRadioContentCell")
    }
    
    //MARK: - SFCarouselViewDelegate -
    
    override func carouselViewNumberOfItems(carouselView: SFCarouselView) -> Int
    {
        return mockData.count
    }
    
    override func carouselView(carouselView: SFCarouselView, cellForItemAtIndex index: Int) -> SFCarouselViewCell
    {
        let dto = mockData[index]
        let identifier = dto.isRadio ? "GLFRadioContentCell" : "GLFBottomContentCell"
        
        if let cell = carouselView.dequeueReusableCellWithIdentifier(identifier) as? GLFContentCell
        {
            presentContentCellWithinViewController(cell, data: dto)
            cell.backgroundColor = dto.isRadio ? .greenColor() : UIColor.redColor()
            
            if !dto.isRadio
            {
                cell.label.text = String(index)
            }
            
            return cell
        }
        
        return SFCarouselViewCell()
    }
    
    func carouselView(carouselView: SFCarouselView, didShowCell cell: SFCarouselViewCell, forItemAtIndex index: Int)
    {
        if let cell = cell as? GLFContentCell, let vc = contentViewControllerByCell(cell)
        {
            vc.didMoveToParentViewController(self)
        }
    }
    
    func carouselView(carouselView: SFCarouselView, didEndDisplayingCell cell: SFCarouselViewCell, forItemAtIndex index: Int)
    {
        if let cell = cell as? GLFContentCell, let vc = contentViewControllerByCell(cell)
        {
            vc.willMoveToParentViewController(nil)
            vc.removeFromParentViewController()
        }
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
