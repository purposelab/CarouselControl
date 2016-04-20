//
//  SFCarouselView.swift
//  SFCarousel
//
//  Created by Pavel Tikhonenko on 07/02/16.
//  Copyright © 2016 Pavel Tikhonenko. All rights reserved.
//

import UIKit

@objc protocol SFCarouselViewDelegate: NSObjectProtocol
{
    func carouselViewNumberOfItems(carouselView: SFCarouselView) -> Int
    func carouselView(carouselView: SFCarouselView, cellForItemAtIndex index: Int) -> SFCarouselViewCell
    
    optional func carouselView(carouselView: SFCarouselView, didShowCell cell: SFCarouselViewCell, forItemAtIndex index: Int)
    optional func carouselView(carouselView: SFCarouselView, didEndDisplayingCell cell: SFCarouselViewCell, forItemAtIndex index: Int)
    optional func carouselViewWillTransitToState(carouselView: SFCarouselView, fastMode: Bool)
    optional func carouselViewDidTransit(carouselView: SFCarouselView, transitionRatio: CGFloat)
    optional func carouselViewDidEndTransititonToState(carouselView: SFCarouselView, fastMode: Bool)
    //MARK: - Menu
    optional func carouselViewMenuCell(carouselView: SFCarouselView) -> SFCarouselViewMenuCell
    optional func carouselViewHasMenu(carouselView: SFCarouselView) -> Bool
    
    optional func carouselView(carouselView: SFCarouselView, didSelectItemAtIndex index: Int)
    optional func carouselViewDidScroll(carouselView: SFCarouselView)
    optional func carouselWillBeginDragging(carouselView: SFCarouselView)
    optional func carouselWillEndDragging(carouselView: SFCarouselView)
}

enum SFCarouselViewState
{
    case Normal
    case Fast
}

class SFCarouselViewLayout
{
    var minimumInteritemSpacing: CGFloat = 8
    var fastModeItemSpace: CGFloat = 20
}

class SFCarouselView: UIView
{
    weak var delegate: SFCarouselViewDelegate?
        {
        didSet {
            reloadData()
        }
    }
    
    var layout: SFCarouselViewLayout!
    
    internal var scrollView: UIScrollView!
    internal var fastMode = false
    internal var animationMode = false
    
    var swipeLocked: Bool = false
    {
        didSet
        {
            scrollView.scrollEnabled = swipeLocked
        }
    }
    
    var fastModeActive: Bool
    {
        return fastMode
    }
    
    var currentState: SFCarouselViewState
    {
        return state(fastMode)
    }
    
    var currentItemIndex: Int
    {
        let offset = scrollView.contentOffset.x
        let elementWidth = currentItemWidth + currentItemSpace
        let index = Int(floor((offset - elementWidth/2)/elementWidth)+1)
        return min(max(index,0), currentItemsCount-1)
    }
    
    internal var currentItemsCount: Int = 0
    
    internal var scrolling: Bool = false
    
    internal var currentItemWidth: CGFloat = 0
    internal var currentItemHeight: CGFloat = 0
    
    internal var fullItemWidth: CGFloat
    {
        return scrollView.frame.width
    }
    
    internal var fullItemHeight: CGFloat
    {
        return scrollView.frame.height
    }
    
    internal var currentItemSpace: CGFloat = 8
    
    internal var fullItemSpace: CGFloat
    {
        return 8
    }
    
    internal var fastModeItemSpace: CGFloat
    {
        return 20
    }
    
    private var scrollVelocity: Int = 0
    private var scrollFinalOffsetX: CGFloat = 0
    private var scrollStartCellIndex = 0
    private lazy var recycledCells = [String:Set<SFCarouselViewCell>]()
    private lazy var registeredCellClasses = [String:SFCarouselViewCell.Type]()
    
    private var visibleRange:Range<Int> {
        return getVisibleCellsIndexesForSize(scrollView.bounds, width:currentItemWidth, space:currentItemSpace)
    }
    // fast mode
    
    
    var menuItemIndex: Int = NSNotFound
    private var hasMenu: Bool { return menuItemIndex != NSNotFound }
    
    private let dW: CGFloat = 120
    private var dH: CGFloat!
    
    
    internal let maxPanYValue: CGFloat = 200
    internal var fastModePan: UIPanGestureRecognizer!
    internal var fastModeTransitionStartY: CGFloat!
    internal var fastModeTransitionInitOffset: CGFloat!
    internal var fastModeTransitionInitContentSize: CGFloat!
    internal var fastModeTransitionPanFinalOffset: CGFloat!
    internal var fastModeTransitionTappedCellIndex: Int!
    internal var fastModeTransitionActive: Bool = false
    
    init(frame: CGRect, layout: SFCarouselViewLayout)
    {
        super.init(frame: frame)
        
        self.layout = layout
        
        initializeScrollView()
        initializeGestureRecognizers()
        calculateInitialValues()
    }
    
    override convenience init(frame: CGRect)
    {
        let layout = SFCarouselViewLayout()
        
        self.init(frame: frame, layout: layout)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        self.layout = SFCarouselViewLayout()
        
        initializeScrollView()
        initializeGestureRecognizers()
        calculateInitialValues()
    }
    
    //MARK: - Public functions -
    
    func resetContentOffset()
    {
        if fastMode
        {
            scrollView.contentOffset = CGPoint(x: -scrollView.contentInset.left, y: 0)
        }else{
            scrollView.contentOffset = CGPoint(x: 0, y: 0)
        }
    }
    
    func reloadData()
    {
        deleteAllItems()
        
        if let delegate = delegate
        {
            let count = delegate.carouselViewNumberOfItems(self)
            currentItemsCount = count
        }
        
        let emptyContent = currentItemsCount == 0
        
        if !emptyContent
        {
            tileCells()
            recalculateContentSize()
        }
        
        userInteractionEnabled = !emptyContent
    }
    
    func dequeueReusableCellWithIdentifier(identifier: String) -> SFCarouselViewCell?
    {
        if let cell = recycledCells[identifier]?.popFirst()
        {
            cell.prepareForReuse()
            return cell
        }
        
        if let classObj = registeredCellClasses[identifier]
        {
            let cell = classObj.init()
            cell.reuseIdentifier = identifier
            cell.prepareForReuse()
            return cell
        }
        
        return nil
    }
    
    func registerClass(cellClass: SFCarouselViewCell.Type?, forCellReuseIdentifier identifier: String)
    {
        registeredCellClasses[identifier] = cellClass
    }
    
    func insertItemAtIndex(index: Int)
    {
        currentItemsCount += 1
        updateVisibleCellIndexes(index, updateFunction: +)
        changeContentOffsetX(scrollView.contentOffset.x + fullItemWidth + fullItemSpace)
        tileCells(true)
    }
    
    func deleteItemAtIndexPath(index: Int)
    {
        currentItemsCount -= 1
        updateVisibleCellIndexes(min(index, currentItemsCount), updateFunction: -)
        changeContentOffsetX(scrollView.contentOffset.x - fullItemWidth - fullItemSpace)
        tileCells(true)
    }
    
    func scrollToItemIdx(itemIdx: Int)
    {
        scrollView.setContentOffset(CGPoint(x: contentOffsetXForIndex(itemIdx), y: 0), animated: true)
    }
}

//MARK: - UIScrollViewDelegate -

internal enum SFCarouselViewScrollDirection
{
    case Left
    case Right
}

extension SFCarouselView: UIScrollViewDelegate
{
    var visibleIndexes: Set<Int>
    {
        return Set(visibleCells.map( { return $0.index } ))
    }
    
    var visibleCells:[SFCarouselViewCell]
    {
        return scrollView.subviews.filter {
            return $0 is SFCarouselViewCell
            } as! [SFCarouselViewCell]
    }
    
    private func visibleCellByIndex(idx: Int) -> SFCarouselViewCell?
    {
        return scrollView.subviews.filter {
            return ($0 is SFCarouselViewCell && $0.tag == idx)
            }.first as? SFCarouselViewCell
    }
    
    private func offsetXForCurrentItem() -> CGFloat
    {
        return contentOffsetXForIndex(currentItemIndex)
    }
    
    internal func recalculateContentSize()
    {
        scrollView.delegate = nil
        scrollView.contentSize = CGSizeMake(getContentWidth(currentItemWidth, itemSpace:currentItemSpace), currentItemHeight)
        scrollView.delegate = self
    }
    
    internal func getContentWidth(itemWidth:CGFloat, itemSpace:CGFloat) -> CGFloat
    {
        if currentItemsCount == 1
        {
            return itemWidth+1 // for float bounds
        }
        
        return itemWidth*CGFloat(currentItemsCount) + itemSpace*CGFloat(currentItemsCount-1)
    }
    
    internal func contentOffsetXForIndex(index:Int) -> CGFloat
    {
        return CGFloat(index)*currentItemWidth + currentItemSpace*CGFloat(index)
    }
    
    internal func getVisibleCellsIndexesForSize(visibleBounds:CGRect, width:CGFloat, space:CGFloat) -> Range<Int>
    {
        if currentItemsCount == 0 { return 0...0 }
        // calc visible cells
        var firstNeededCellIndex = Int(floor(CGRectGetMinX(visibleBounds)/(width+space)))
        var lastNeededCellIndex = Int(floor((CGRectGetMaxX(visibleBounds))/(width+space)))
        firstNeededCellIndex = min(max(firstNeededCellIndex, 0), max(currentItemsCount - 1, 0))
        lastNeededCellIndex = min(lastNeededCellIndex, max(currentItemsCount - 1, 0))
        
        
        if lastNeededCellIndex < 0
        {
            lastNeededCellIndex = currentItemsCount > 0 ? 1 : 0
        }
        
        return firstNeededCellIndex...lastNeededCellIndex
    }
    
    internal func deleteAllItems()
    {
        for item in scrollView.subviews
        {
            item.removeFromSuperview()
        }
        
        recycledCells.removeAll()
    }
    
    internal func tileCells(sizeChanged:Bool = false)
    {
        if currentItemsCount == 0 { return }
        
        tileCells(visibleRange, sizeChanged: sizeChanged)
    }
    
    internal func recycleCells(visibleRange: Range<Int>)
    {
        
        let cells = visibleCells
        let s:Set<Int> = visibleIndexes.subtract(visibleRange)
        
        if s.count > 0
        {
            cells.forEach { (item) -> () in
                if s.contains(item.index)
                {
                    //print("recycleCells \(item.index)")
                    
                    animationMode ? placeCell(item) : recycleCell(item)
                }
            }
        }
    }
    
    private func recycleCell(cell: SFCarouselViewCell)
    {
        if let identifier = cell.reuseIdentifier
        {
            initializeRecycleDictKey(identifier)
            recycledCells[identifier]?.insert(cell)
        }
        
        //cell.clear()
        cell.removeFromSuperview()
        delegate?.carouselView?(self, didEndDisplayingCell: cell, forItemAtIndex: cell.index)
    }
    
    internal func tileCells(range: Range<Int>, sizeChanged:Bool = false)
    {
        if currentItemsCount == 0 { return }
        
        let visible = visibleIndexes
        let addingIndexes:Set<Int> = Set(range).subtract(visible)
        
        
        for item in addingIndexes.enumerate()
        {
            addCellToVisible(item.element)
        }
        
        if sizeChanged
        {
            let changingSizeIndexes:Set<Int> = visible.union(range)
            
            for item in changingSizeIndexes.enumerate()
            {
                if let cell = visibleCellByIndex(item.element)
                {
                    //print("place visible cell \(item.element)")
                    placeCell(cell)
                }
            }
        }
    }
    
    internal func addCellToVisible(index:Int)
    {
        var tempIndex = index
        
        if index > menuItemIndex
        {
            tempIndex -= 1
        }
        
        if index == menuItemIndex
        {
            if let cell = delegate?.carouselViewMenuCell?(self)
            {
                //print("addCellToVisible Menu \(index)")
                
                cell.tag = index
                addAndPlaceCell(cell)
            }
        }else if let cell = delegate?.carouselView(self, cellForItemAtIndex: tempIndex)
        {
            //print("addCellToVisible \(index)")
            
            cell.tag = index
            addAndPlaceCell(cell)
            delegate?.carouselView?(self, didShowCell: cell, forItemAtIndex: tempIndex)
        }
    }
    
    internal func addAndPlaceCell(cell:SFCarouselViewCell)
    {
        cell.userInteractionEnabled = !fastMode
        placeCell(cell)
        scrollView.addSubview(cell)
    }
    
    internal func placeCell(cell:SFCarouselViewCell)
    {
        cell.frame = CGRectMake(contentOffsetXForIndex(cell.index), (fullItemHeight-currentItemHeight)*0.70, currentItemWidth, currentItemHeight)
        //cell.sizeChanged(false)
    }
    
    
    internal func nextItemIndex(currentItemIdx: Int, direction: SFCarouselViewScrollDirection) -> Int
    {
        var idx = currentItemIdx + (direction == .Left ? 1 : -1)
        idx = min(max(idx, 0), currentItemsCount - 1)
        return idx
    }
    
    internal func scrollDirection(scrollView: UIScrollView) -> SFCarouselViewScrollDirection
    {
        let scrollVelocity = Int(scrollView.panGestureRecognizer.velocityInView(self).x)
        return scrollVelocity < 0 ? SFCarouselViewScrollDirection.Left : SFCarouselViewScrollDirection.Right
    }
    
    internal func changeContentOffsetX(offset:CGFloat)
    {
        var scrollBounds = scrollView.bounds
        scrollBounds.origin.x = offset
        scrollView.bounds = scrollBounds
        //print("changeContentOffsetX \(offset)")
    }
    
    private func updateVisibleCellIndexes(startIndex: Int, updateFunction: (lhs: Int, rhs: Int)->Int)
    {
        let cells = visibleCells
        cells.filter({ $0.index >= startIndex }).forEach { (cell) -> () in
            cell.tag = updateFunction(lhs: cell.index, rhs: 1)
            
            if cell is SFCarouselViewMenuCell
            {
                cell.tag = NSNotFound
            }
        }
    }
    
    internal func startScrollingSession()
    {
        scrolling = true
        
        if !fastMode
        {
            scrollStartCellIndex = currentItemIndex
            disableScrolling()
        }
    }
    
    internal func endScrollingSession()
    {
        scrolling = false
        
    }
    
    func disablePan()
    {
        fastModePan.enabled = false
        
        self.visibleCells.forEach({ (item) -> () in
            item.userInteractionEnabled = true
        })
    }
    
    func enablePan()
    {
        fastModePan.enabled = true
    }
    
    func enableScrolling()
    {
        //scrollView.userInteractionEnabled = true
    }
    
    func disableScrolling()
    {
        //scrollView.userInteractionEnabled = false
    }
    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView)
    {
        let scrollVelocity = Int(scrollView.panGestureRecognizer.velocityInView(self).x)
        
        if !fastMode && abs(scrollVelocity) >= 100
        {
            animationMode = true
            placeCellsBeforeAnimation()
            // disable decelerating
            scrollView.setContentOffset(scrollView.contentOffset, animated: true)
            
            // scroll to nearest cell
            let index = nextItemIndex(scrollStartCellIndex, direction: scrollDirection(scrollView))
            scrollFinalOffsetX = contentOffsetXForIndex(index)
            
            UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                
                self.scrollView.contentOffset = CGPointMake(self.scrollFinalOffsetX,0)
                }, completion: { res in
                    self.scrollVelocity = 0
                    self.animationMode = false
                    self.tileCells()
                    self.recycleCells(self.visibleRange)
                    //                    self.invalidateVisibleCellsExceptIndex(index)
            })
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView)
    {
        print("vDidScroll \(scrollView.contentOffset.x)")
        
        if currentItemsCount > 0
        {
            tileCells()
            recycleCells(visibleRange)
            
            delegate?.carouselViewDidScroll?(self)
        }
        
        if !scrolling && scrollView.contentOffset.x == scrollFinalOffsetX
        {
            enablePan()
            enableScrolling()
        }
        
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        
        delegate?.carouselWillEndDragging?(self)
        if !fastMode
        {
            if velocity.x == 0
            {
                targetContentOffset.memory.x = offsetXForCurrentItem()
            }else{
                scrollVelocity = Int(velocity.x)
            }
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView)
    {
        delegate?.carouselWillBeginDragging?(self)
        startScrollingSession()
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView)
    {
        //print("ScrollView Did End Scrolling Animation >>>>>")
        endScrollingSession()
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView)
    {
        //print("scroll View Did End Decelerating >>>>>")
        
        endScrollingSession()
        
        if !fastMode {
            if scrollVelocity == 0
            {
                enableScrolling()
            }
        }
    }
}


//MARK: - Life cycle -

extension SFCarouselView
{
    internal func initializeScrollView()
    {
        scrollView = UIScrollView(frame: bounds)
        scrollView.backgroundColor = UIColor.clearColor()
        scrollView.delegate = self
        scrollView.contentInset = fastMode ? UIEdgeInsetsMake(0, dW/2, 0, dW/2) : UIEdgeInsetsZero
        scrollView.decelerationRate = fastMode ? UIScrollViewDecelerationRateNormal : UIScrollViewDecelerationRateFast
        addSubview(scrollView)
    }
    
    internal func initializeGestureRecognizers()
    {
        fastModePan = UIPanGestureRecognizer(target: self, action: #selector(SFCarouselView.fastModePanHandler(_:)))
        fastModePan.delegate = self
        scrollView.addGestureRecognizer(fastModePan)
        
        let touch = UITapGestureRecognizer(target: self, action: #selector(SFCarouselView.touchViewTapHandler(_:)))
        scrollView.addGestureRecognizer(touch)
    }
    
    internal func calculateInitialValues()
    {
        dH = fullItemHeight*dW/fullItemWidth
        
        
        let translate = fastMode ? maxPanYValue : 0
        let itemSize = getItemSizeForTranslate(translate, maxPanYValue: maxPanYValue)
        let spaceValue = getSpaceForTranslate(translate, maxPanYValue: maxPanYValue)
        
        currentItemWidth = itemSize.width
        currentItemHeight  = itemSize.height
        currentItemSpace = spaceValue
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        scrollView.frame = bounds
        tileCells()
    }
}

//MARK: - Fastmode transition -

extension SFCarouselView: UIGestureRecognizerDelegate
{
    func transitionGestureRecognizeActive() -> Bool
    {
        if fastModePan.numberOfTouches() > 0
        {
            let velocity = fastModePan.velocityInView(scrollView)
            let location = fastModePan.locationOfTouch(0, inView: scrollView)
            return (!fastModeActive && (-velocity.y > fabs(velocity.x) || location.y > 0.85*fullItemHeight))
        } else {
            return false
        }
    }
    
    internal func redrawCellsForItemSize(size:CGSize, space:CGFloat)
    {
        currentItemWidth = size.width
        currentItemHeight = size.height
        currentItemSpace = space
        tileCells(true)
    }
    
    private func recalcCellSize(tranlsateY:CGFloat, cellIndex:Int?)
    {
        let itemSize = getItemSizeForTranslate(tranlsateY, maxPanYValue: maxPanYValue)
        let spaceValue = getSpaceForTranslate(tranlsateY, maxPanYValue: maxPanYValue)
        
        var offsetX: CGFloat!
        
        if cellIndex != nil
        {
            offsetX = CGFloat(cellIndex!)*(fullItemWidth + fullItemSpace)
        } else {
            offsetX = getOffsetXForTranslate(tranlsateY, itemWidth:itemSize.width, spaceValue:spaceValue)
        }
        
        changeContentOffsetX(offsetX)
        redrawCellsForItemSize(itemSize, space:spaceValue)
        recalculateContentSize()
        
        delegate?.carouselViewDidTransit?(self, transitionRatio: tranlsateY/maxPanYValue)
    }
    
    
    private func getCellByTouch(recognizer:UIGestureRecognizer, preventMenuTouch:Bool = true) -> SFCarouselViewCell?
    {
        let array = visibleCells.sort { (cell1, cell2) -> Bool in
            return cell1.tag < cell2.tag
            }.filter { (item) -> Bool in
                return !(item is SFCarouselViewTransitionCell)
        }
        
        let count = array.count
        
        for (idx, cell) in array.enumerate()
        {
            if cell.pointInside(recognizer.locationInView(cell), withEvent: nil)
            {
                if preventMenuTouch && cell.preventFastModeTransition
                {
                    var nextIdx: Int = idx
                    
                    if idx < count-1
                    {
                        nextIdx += 1
                    }else{
                        nextIdx -= 1
                        
                    }
                    
                    return array[nextIdx]
                }
                
                return cell
            }
        }
        
        return nil
    }
    
    func touchViewTapHandler(recognizer:UITapGestureRecognizer)
    {
        var touchProcessed = false
        
        if fastMode
        {
            if let cell = getCellByTouch(recognizer, preventMenuTouch: false)
            {
                if !(cell is SFCarouselViewMenuCell)
                {
                    delegate?.carouselView?(self, didSelectItemAtIndex: cell.index)
                    delegate?.carouselViewWillTransitToState?(self, fastMode: false)
                    panEndedAnimated(false, cellIndex:cell.index)
                    touchProcessed = true
                }
            }
        }
        
        if !touchProcessed
        {
            recognizer.cancelsTouchesInView = false
        }
    }
    
    func fastModePanHandler(recognizer:UIPanGestureRecognizer)
    {
        if recognizer.state != .Began && fastModeTransitionTappedCellIndex == nil
        {
            return
        }
        
        let point = recognizer.locationInView(self)
        
        switch recognizer.state {
        case .Began:
            fastModeTransitionActive = true
            
            fastModeTransitionStartY = point.y
            
            if let cell = getCellByTouch(recognizer)
            {
                
                fastModeTransitionTappedCellIndex = cell.tag
                
                if fastMode {
                    fastModeTransitionPanFinalOffset = CGFloat(cell.tag) * (fullItemWidth + fullItemSpace)
                    fastModeTransitionStartY = fastModeTransitionStartY - maxPanYValue
                } else {
                    
                    if cell.preventFastModeTransition
                    {
                        return
                    }
                    
                    if tryToAddMenuItemAtIndex(cell.index)
                    {
                        fastModeTransitionTappedCellIndex! += 1
                    }else{
                    }
                    
                    
                }
            }
            
            fastModeTransitionInitOffset = scrollView.contentOffset.x
            fastModeTransitionInitContentSize = (fullItemWidth + fullItemSpace) * CGFloat(currentItemsCount) - fullItemSpace
            delegate?.carouselViewWillTransitToState?(self, fastMode: !fastMode)
        //showCellsSnapshot()
        case .Changed:
            
            var tranlsateY = point.y - fastModeTransitionStartY
            
            if tranlsateY < 0
            {
                tranlsateY = -slowdownFunction(tranlsateY)
            }else if tranlsateY > maxPanYValue
            {
                tranlsateY = maxPanYValue + slowdownFunction(tranlsateY-maxPanYValue)
            }
            
            recalcCellSize(tranlsateY, cellIndex: nil)
        case .Ended:
            let velocity = recognizer.velocityInView(self)
            let toSmall = velocity.y > 0
            panEndedAnimated(toSmall, cellIndex: toSmall ? nil : fastModeTransitionTappedCellIndex) {
                self.recycleCells(self.visibleRange)
                self.visibleCells.forEach({ (item) -> () in
                    item.userInteractionEnabled = !toSmall
                })
                
                self.enablePan()
                self.enableScrolling()
            }
            
            fastModeTransitionTappedCellIndex = nil
            
        default:
            break
        }
    }
    
    internal func panEndedAnimated(small:Bool, cellIndex:Int? = nil, completion:(()->())? = nil)
    {
        if small
        {
            placeNeededCellsBeforeAnimation()
        }
        
        UIView.animateWithDuration(0.35, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.panEnded(small, cellIndex: cellIndex)
            }, completion: { finished in
                self.scrollView.decelerationRate = small ? UIScrollViewDecelerationRateNormal : UIScrollViewDecelerationRateFast
                
                if !small
                {
                    self.hideMenuItem()
                }
                
                self.fastModeTransitionActive = false
                
                self.delegate?.carouselViewDidEndTransititonToState?(self, fastMode: small)
                
                completion?()
        })
    }
    
    internal func panEnded(small:Bool, cellIndex:Int?)
    {
        if small
        {
            //SFAnalytics.sendEvent(.Menu, action:"pullDown")
        }
        
        scrollView.contentInset = small ? UIEdgeInsetsMake(0, dW/2, 0, dW/2) : UIEdgeInsetsZero
        recalcCellSize(small ? maxPanYValue : 0, cellIndex:cellIndex)
        fastMode = small
    }
    
    private func placeCellsBeforeAnimation()
    {
        var rect = scrollView.bounds
        rect.origin.x -= fullItemWidth
        rect.size.width += 2*fullItemWidth
        
        let visibleRange = getVisibleCellsIndexesForSize(rect, width:currentItemWidth, space:currentItemSpace)
        tileCells(visibleRange)
    }
    
    private func placeNeededCellsBeforeAnimation()
    {
        let b = scrollView.bounds
        let itemWidth = getItemWidthForTranslate(maxPanYValue, maxPanYValue: maxPanYValue)
        let spaceValue = getSpaceForTranslate(maxPanYValue, maxPanYValue: maxPanYValue)
        let offsetX = getOffsetXForTranslate(maxPanYValue, itemWidth:itemWidth, spaceValue:spaceValue)
        let visibleBounds = CGRectMake(offsetX, b.origin.y, b.width, b.height)
        tileCells(getVisibleCellsIndexesForSize(visibleBounds, width:itemWidth, space:spaceValue), sizeChanged: true)
    }
    
    private func tryToAddMenuItemAtIndex(index:Int) -> Bool
    {
        if let hasMenu = delegate?.carouselViewHasMenu?(self)
        {
            if !hasMenu { return false }
        }else{
            return false
        }
        
        if menuItemIndex == NSNotFound
        {
            addMenuItemAtIndex(index)
            return true
        }
        
        return false
    }
    
    private func addMenuItemAtIndex(index:Int)
    {
        menuItemIndex = index
        insertItemAtIndex(index)
    }
    
    private func hideMenuItem()
    {
        if menuItemIndex == NSNotFound { return }
        
        let menuIdx = menuItemIndex
        
        menuItemIndex = NSNotFound
        deleteItemAtIndexPath(menuIdx)
        tileCells(max(0, menuIdx-1)...menuIdx)
    }
    
    
    
    private func getItemWidthForTranslate(tranlsateY:CGFloat, maxPanYValue: CGFloat) -> CGFloat
    {
        return fullItemWidth - timingFunction(tranlsateY, diff:dW, maxPanYValue: maxPanYValue)
    }
    
    private func getItemSizeForTranslate(tranlsateY:CGFloat, maxPanYValue: CGFloat) -> CGSize
    {
        let w = fullItemWidth - timingFunction(tranlsateY, diff:dW, maxPanYValue: maxPanYValue)
        let h = fullItemHeight - timingFunction(tranlsateY, diff:dH, maxPanYValue: maxPanYValue)
        return CGSize(width: w, height: h)
    }
    
    private func getSpaceForTranslate(tranlsateY:CGFloat, maxPanYValue: CGFloat) -> CGFloat
    {
        return fullItemSpace - timingFunction(tranlsateY, diff:fullItemSpace - fastModeItemSpace, maxPanYValue: maxPanYValue)
    }
    
    private func getOffsetXForTranslate(translateY:CGFloat, itemWidth:CGFloat, spaceValue:CGFloat) -> CGFloat
    {
        if fastMode {
            return getOffsetXForSmallView(translateY)
        } else {
            return getOffsetXForBigView(translateY, itemWidth:itemWidth, spaceValue:spaceValue)
        }
    }
    
    private func getOffsetXForSmallView(translateY:CGFloat) -> CGFloat
    {
        var offsetX:CGFloat
        let diff = fastModeTransitionPanFinalOffset-fastModeTransitionInitOffset
        let diffOffset = timingFunction(translateY, diff:diff, maxPanYValue: maxPanYValue)
        
        if (diff > 0 && diffOffset < 0) || (diff < 0 && diffOffset > 0)
        { // overscroll in big view
            offsetX = contentOffsetXForIndex(fastModeTransitionTappedCellIndex) + (currentItemWidth-fullItemWidth)/2
        } else {
            offsetX = fastModeTransitionPanFinalOffset-diffOffset
        }
        return offsetX
    }
    
    private func getOffsetXForBigView(translateY:CGFloat, itemWidth:CGFloat, spaceValue:CGFloat) -> CGFloat
    {
        let ratio = translateY/maxPanYValue
        
        var offsetX:CGFloat
        let translateOffset = timingFunction(translateY, diff:fullItemWidth + spaceValue - dW/2, maxPanYValue: maxPanYValue)
        
        if translateOffset < 0
        { // overscroll in big view
            offsetX = contentOffsetXForIndex(fastModeTransitionTappedCellIndex) + (currentItemWidth-fullItemWidth)/2
        } else {
            let extraOffset = hasMenu ? translateOffset : ratio*dW/2
            
            offsetX = (getContentWidth(itemWidth, itemSpace:spaceValue) * fastModeTransitionInitOffset / fastModeTransitionInitContentSize) - extraOffset
            
            //TODO: strange thing
            offsetX = max(offsetX, -dW/2)
            
            if scrollView.contentInset.left == 0 && offsetX < 0
            {
                offsetX = 0
            }
        }
        
        return offsetX
    }
    
    //MARK - Gesture Recornizer Delegate
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        super.gestureRecognizerShouldBegin(gestureRecognizer)
        
        if gestureRecognizer != fastModePan
        {
            if scrolling || !fastModePan.enabled || fastModeTransitionActive || fastModeActive { return false }
            
            if fastModePan.numberOfTouches() > 0
            {
                let velocity = fastModePan.velocityInView(scrollView)
                let location = fastModePan.locationOfTouch(0, inView: scrollView)
                return (!fastModeActive && (-velocity.y > fabs(velocity.x) || location.y > 0.85*fullItemHeight))
            } else {
                return false
            }
        }
        
        if scrolling { return false }
        
        if fastModePan.numberOfTouches() > 0
        {
            let velocity = fastModePan.velocityInView(scrollView)
            return (!fastModeActive && velocity.y > fabs(velocity.x)) || (fastModeActive && fabs(velocity.y) > fabs(velocity.x))
        } else {
            return false
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if gestureRecognizer == fastModePan
        {
            return false
        }
        
        return true
    }
}

//MARK: - Utils -

extension SFCarouselView
{
    internal func initializeRecycleDictKey(key: String)
    {
        if recycledCells[key] == nil
        {
            recycledCells[key] = Set<SFCarouselViewCell>()
        }
    }
    
    internal func state(fastMode: Bool) -> SFCarouselViewState
    {
        return fastMode ? .Fast : .Normal
    }
}

// MARK: - Timing function -

private func slowdownFunction(value:CGFloat) -> CGFloat
{
    return sqrt(10*fabs(value))
}

private func timingFunction(tranlsate:CGFloat, diff:CGFloat, maxPanYValue: CGFloat) -> CGFloat
{
    let result = timingFunctionEraseInOut(tranlsate, diff:diff, maxTranslate:maxPanYValue)
    
    if tranlsate < 0
    {
        return -result
    } else if tranlsate < maxPanYValue
    {
        return result
    } else
    {
        return diff + (diff-result)
    }
}

private func timingFunctionEraseIn(tranlsate:CGFloat, diff:CGFloat, maxPanYValue: CGFloat) -> CGFloat
{
    return pow(tranlsate / maxPanYValue, 2) * diff
}

private func timingFunctionEraseOut(tranlsate:CGFloat, diff:CGFloat, maxPanYValue: CGFloat) -> CGFloat
{
    let t = tranlsate / maxPanYValue
    return -diff*t*(t-2)
}

private func timingFunctionEraseInOut(tranlsate:CGFloat, diff:CGFloat, maxTranslate:CGFloat) -> CGFloat
{
    var a = 2 * tranlsate / maxTranslate
    
    if a < 1
    {
        return pow(a,2)*diff/2
    }
    
    a--
    
    return -diff/2*(a*(a-2)-1)
}