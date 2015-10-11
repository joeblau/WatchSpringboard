//
//  SpringboardView.swift
//  WatchSpringboard
//
//  Created by Joe Blau on 11/1/14.
//  Copyright (c) 2014 joeblau. All rights reserved.
//

import UIKit

func PointDistanceSquared(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat) -> CGFloat {
    return sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2))
}

func PointDistance(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat) -> CGFloat {
    return ((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2))
}

class SpringboardView: UIScrollView, UIScrollViewDelegate {
    
    let touchView: UIView! = UIView()
    let contentView: UIView! = UIView()
    var transformFactor: CGFloat!
    var lastFocusedViewIndex: UInt! = 0
    var zoomScaleCache: CGFloat!
    var minTransform: CGAffineTransform!
    var isMinZoomLevelDirty: Bool = true
    var isContentSizeDirty: Bool = true
    var contentSizeUnscaled: CGSize!
    var contentSizeExtra: CGSize!
    var centerOnEndDrag: Bool = true
    var centerOnEndDecelerate: Bool = true
    var minimumZoomLevelInteraction: CGFloat!
    var doubleTapGesture: UITapGestureRecognizer!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    override var bounds: CGRect {
        didSet {
            if CGSizeEqualToSize(bounds.size, self.bounds.size) == false {
                setMinimumZoomLevelIsDirty()
            }
            super.bounds = bounds
        }
    }
    
    override var frame: CGRect {
        didSet {
            if CGSizeEqualToSize(frame.size, self.bounds.size) == false {
                setMinimumZoomLevelIsDirty()
            }
            super.frame = frame
        }
    }
    
    var itemViews: [SpringboardItemView]! {
        willSet {
            if let views = itemViews {
                for view in views {
                    if view.isDescendantOfView(self) {
                        view.removeFromSuperview()
                    }
                }
            }
        }
        
        didSet {
            for view in itemViews {
                contentView.addSubview(view)
            }
            setMinimumZoomLevelIsDirty()
        }
    }
    
    var itemDiameter: UInt! {
        didSet {
            setMinimumZoomLevelIsDirty()
        }
    }
    
    var itemPadding: UInt! {
        didSet {
            setMinimumZoomLevelIsDirty()
        }
    }
    
    var minimumItemScaling: CGFloat! {
        didSet {
            setNeedsLayout()
        }
    }
    
    func showAllContent(animated: Bool) {
        let contentRectInContentSpace = fullContentRectInContentSpace()
        lastFocusedViewIndex = closestIndexToPointInContent(rectCenter(contentRectInContentSpace))
        
        if animated {
            UIView.animateWithDuration(0.5, delay: 0, options: [.LayoutSubviews, .AllowAnimatedContent, .BeginFromCurrentState, .CurveEaseInOut], animations: { () -> Void in
                self.zoomToRect(contentRectInContentSpace, animated: false)
                self.layoutIfNeeded()
                }, completion: nil)
        } else {
            zoomToRect(contentRectInContentSpace, animated: false)
        }
    }
    
    func indexOfItemClosestTo(point: CGPoint) -> UInt {
        return closestIndexToPointInContent(point)
    }
    
    func centerOn(index: UInt, zoomScale: CGFloat, animated: Bool) {
        lastFocusedViewIndex = index
        let view = itemViews[Int(index)]
        let centerContentSpace = view.center
        
        if zoomScale == self.zoomScale {
            let sizeInSelfSpace = self.bounds.size
            let centerInSelfSpace = pointInContentToSelf(centerContentSpace)
            let rectInSelfSpace = rectWithCenter(centerInSelfSpace, size: sizeInSelfSpace)
            scrollRectToVisible(rectInSelfSpace, animated: animated)
        } else {
            let rectInContentSpace = rectWithCenter(centerContentSpace, size: view.bounds.size)
            zoomToRect(rectInContentSpace, animated: animated)
        }
    }
    
    func doIntroAnimation() {
        layoutIfNeeded()
        
        let size = self.bounds.size
        var idx: UInt = 0
        let minScale:CGFloat = 0.5
        let centerView = itemViews[Int(lastFocusedViewIndex)]
        let centerViewCenter = centerView.center
        for view in itemViews {
            let viewCenter = view.center
            view.alpha = 0
            let dx = viewCenter.x - centerViewCenter.x
            let dy = viewCenter.y - centerViewCenter.y
            let distance = (dx * dx - dy * dy)
            let factor = max(min(max(size.width, size.height) / distance, 1), 0)
            let scaleFactor: CGFloat = ((factor) * 0.8 + 0.2)
            let translateFactor: CGFloat = -0.9
            
            view.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(dx*translateFactor, dy * translateFactor),
                minScale*scaleFactor, minScale*scaleFactor)
            idx++
        }
        
        setNeedsLayout()
        UIView.animateWithDuration(0.5, delay: 0, options: .CurveEaseOut, animations: { () -> Void in
            for view in self.itemViews {
                view.alpha = 1
            }
            self.layoutSubviews()
            }, completion: nil)
    }
    
    // MARK: - UITapGestureRecognizer
    
    func didZoomGesture(sender: UITapGestureRecognizer) {

        
        if zoomScale >= minimumZoomLevelInteraction && zoomScale != minimumZoomScale {
            showAllContent(true)
        } else {
            let positionInSelf = sender.locationInView(self)
            let targetIndex = closestIndexToPointInContent(positionInSelf)
            print(targetIndex)
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.centerOn(targetIndex-1, zoomScale: 1, animated: false)
                self.layoutIfNeeded()
                }, completion: nil)
        }
    }
    
    // MARK: - Private Functions
    func initialize() {
        delaysContentTouches = false
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        alwaysBounceHorizontal = true
        alwaysBounceVertical = true
        bouncesZoom = true
        decelerationRate = UIScrollViewDecelerationRateFast
        delegate = self
        
        self.itemDiameter = 68
        itemPadding = 48
        minimumItemScaling = 0.5
        
        transformFactor = 1
        zoomScaleCache = zoomScale
        minimumZoomLevelInteraction = 0.4
        
        addSubview(touchView)
        addSubview(contentView)
        
        doubleTapGesture = UITapGestureRecognizer(target: self, action: "didZoomGesture:")
        doubleTapGesture.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTapGesture)
        
    }
    
    func pointInSelfToContent(point: CGPoint) -> CGPoint {
        let zoomScale = self.zoomScale
        return CGPointMake(point.x/zoomScale, point.y/zoomScale)
    }
    
    func pointInContentToSelf(point: CGPoint) -> CGPoint {
        let zoomScale = self.zoomScale
        return CGPointMake(point.x*zoomScale, point.y*zoomScale)
    }
    
    func sizeInSelfToContent(size: CGSize) -> CGSize {
        let zoomScale = self.zoomScale
        return CGSizeMake(size.width/zoomScale, size.height/zoomScale)
    }
    
    func sizeInContentToSelf(size: CGSize) -> CGSize {
        let zoomScale = self.zoomScale
        return CGSizeMake(size.width*zoomScale, size.height*zoomScale)
    }
    
    func rectCenter(rect: CGRect) -> CGPoint {
        return CGPointMake(rect.origin.x+rect.size.width*0.5, rect.origin.y+rect.size.height*0.5)
    }
    
    func rectWithCenter(center: CGPoint, size: CGSize) -> CGRect {
        return CGRectMake(center.x-size.width*0.5, center.y-size.height*0.5, size.width, size.height)
    }
    
    func transformView(view: SpringboardItemView) {
        let size = self.bounds.size
        let zoomScale = zoomScaleCache
        let insets = self.contentInset
        
        var center = view.center
        let floatDiameter = CGFloat(itemDiameter)
        let floatPadding = CGFloat(itemPadding)
        var frame = self.convertRect(CGRectMake(view.center.x - floatDiameter/2, view.center.y - floatDiameter/2, floatDiameter, floatDiameter), fromView: view.superview)
        let contentOffset = self.contentOffset
        frame.origin.x -= contentOffset.x
        frame.origin.y -= contentOffset.y
        center = CGPointMake(frame.origin.x+frame.size.width/2, frame.origin.y+frame.size.height/2)
        let padding = floatPadding * zoomScale * 0.4
        var distanceToBorder: CGFloat = size.width
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        
        let distanceToBeOffset = floatDiameter * zoomScale * (min(size.width, size.height)/320)
        let leftDistance = center.x - padding - insets.left
        if leftDistance < distanceToBeOffset {
            if leftDistance < distanceToBorder {
                distanceToBorder = leftDistance
            }
            xOffset = 1 - leftDistance / distanceToBeOffset
        }
        let topDistance = center.y - padding - insets.top
        if topDistance < distanceToBeOffset {
            if topDistance < distanceToBorder {
                distanceToBorder = topDistance
            }
            yOffset = 1 - topDistance / distanceToBeOffset
        }
        let rightDistance = size.width - padding - center.x - insets.right
        if rightDistance < distanceToBeOffset {
            if rightDistance < distanceToBorder {
                distanceToBorder = rightDistance
            }
            xOffset = -(1 - rightDistance / distanceToBeOffset)
        }
        let bottomDistance = size.height - padding - center.y - insets.bottom
        if bottomDistance < distanceToBeOffset {
            if bottomDistance < distanceToBorder {
                distanceToBorder = bottomDistance
            }
            yOffset = -(1 - bottomDistance / distanceToBeOffset)
        }
        
        distanceToBorder *= 2
        var usedScale: CGFloat!
        if distanceToBorder < distanceToBeOffset * 2 {
            if distanceToBorder < -(floatDiameter*2.5) {
                view.transform = minTransform
                usedScale = minimumItemScaling * zoomScale
            } else {
                var rawScale = max(distanceToBorder / (distanceToBeOffset * 2), 0)
                rawScale = min(rawScale,1)
                rawScale = 1 - ((1-rawScale) * (1-rawScale))
                var scale = rawScale * (1 - minimumItemScaling) + minimumItemScaling
                
                xOffset = frame.size.width * 0.8 * (1 - rawScale) * xOffset
                yOffset = frame.size.width * 0.5 * (1 - rawScale) * yOffset
                
                var translationModifier = min(distanceToBorder / floatDiameter+2.5, 1)
                
                scale = max(min(scale * transformFactor + (1 - transformFactor), 1), 0)
                translationModifier = min(translationModifier * transformFactor, 1)
                view.transform = CGAffineTransformTranslate(CGAffineTransformMakeScale(scale, scale), xOffset * translationModifier, yOffset * translationModifier)
                
                usedScale = scale * zoomScale
            }
        } else {
            view.transform = CGAffineTransformIdentity
            usedScale = zoomScale
        }
        if self.dragging || self.zooming {
            view.setScale(usedScale, animated: true)
        } else {
            view.scale = usedScale
        }
    }
    
    func setMinimumZoomLevelIsDirty() {
        isMinZoomLevelDirty = true
        isContentSizeDirty = true
        setNeedsLayout()
    }
    
    func closestIndexToPointInSelf(pointInSelf: CGPoint) -> UInt {
        let pointInContent = self.pointInContentToSelf(pointInSelf)
        return closestIndexToPointInContent(pointInContent)
    }
    
    func closestIndexToPointInContent(pointInContent: CGPoint) -> UInt {
        var distance = CGFloat(FLT_MAX)
        var index = lastFocusedViewIndex
        for (idx, view) in itemViews.enumerate() {
            
            let center = CGPointMake(view.center.x / UIScreen.mainScreen().scale, view.center.y / UIScreen.mainScreen().scale)
            let potentialDistance = PointDistance(center.x, y1: center.y, x2: pointInContent.x, y2: pointInContent.y)
            
            if (potentialDistance < distance) {
                distance = potentialDistance
                index = UInt(idx)
            }
        }
        return index
    }
    
    func centerOnClosestToScreenCenterAnimated(animated: Bool) {
        let sizeInSelf = self.bounds.size
        let centerInSelf = CGPointMake(sizeInSelf.width * 0.5, sizeInSelf.height * 0.5)
        let closestIndex = self.closestIndexToPointInSelf(centerInSelf)
        self.centerOn(closestIndex, zoomScale: zoomScale, animated: animated)
    }
    
    func fullContentRectInContentSpace() -> CGRect {
        return CGRectMake(self.contentSizeExtra.width*0.5,
            contentSizeExtra.height*0.5,
            contentSizeUnscaled.width - contentSizeExtra.width,
            contentSizeUnscaled.height - contentSizeExtra.height)
    }
    
    // MARK: UIScrollViewDelegate
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let size = self.bounds.size
        let zoomScale = self.zoomScale
        
        var proposedTargetCenter = CGPointMake(targetContentOffset.memory.x+size.width/2, targetContentOffset.memory.y+size.height/2)
        proposedTargetCenter.x /= zoomScale
        proposedTargetCenter.y /= zoomScale
        
        lastFocusedViewIndex = closestIndexToPointInContent(proposedTargetCenter)
        let view = itemViews[Int(lastFocusedViewIndex)]
        let idealTargetCenter = view.center
        
        let idealTargetOffset = CGPointMake(idealTargetCenter.x-size.width/2/zoomScale,
            idealTargetCenter.y-size.height/2/zoomScale)
        
        let correctedTargetOffset = CGPointMake(idealTargetOffset.x*zoomScale,
            idealTargetOffset.y*zoomScale)
        
        var currentCenter = CGPointMake(self.contentOffset.x+size.width/2, self.contentOffset.y+size.height/2)
        currentCenter.x /= zoomScale
        currentCenter.y /= zoomScale
        
        var contentCenter = contentView.center
        contentCenter.x /= zoomScale
        contentCenter.y /= zoomScale
        
        let contentSizeNoExtras = CGSizeMake(contentSizeUnscaled.width-contentSizeExtra.width,
            contentSizeUnscaled.height-contentSizeExtra.height)
        let contentFrame = CGRectMake(contentCenter.x-contentSizeNoExtras.width*0.5, contentCenter.y-contentSizeNoExtras.height*0.5, contentSizeNoExtras.width, contentSizeNoExtras.height)
        
        if CGRectContainsPoint(contentFrame, proposedTargetCenter) {
            targetContentOffset.memory = correctedTargetOffset
        } else {
            if CGRectContainsPoint(contentFrame, currentCenter) {
                let ourPriority: CGFloat = 0.8
                
                targetContentOffset.memory = CGPointMake(
                    targetContentOffset.memory.x*(1.0-ourPriority)+correctedTargetOffset.x*ourPriority,
                    targetContentOffset.memory.y*(1.0-ourPriority)+correctedTargetOffset.y*ourPriority)
                centerOnEndDecelerate = true
            } else {
                targetContentOffset.memory = contentOffset
            }
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if centerOnEndDrag {
            centerOnEndDrag = false
            centerOn(lastFocusedViewIndex, zoomScale: zoomScale, animated: true)
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if centerOnEndDecelerate {
            centerOnEndDecelerate = false
            centerOn(lastFocusedViewIndex, zoomScale: zoomScale, animated: true)
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        zoomScaleCache = zoomScale
    }
    
    // MARK: UIView
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        let size = bounds.size
        let insets = contentInset
        
        
        let items = min(size.width,size.height) / max(size.width,size.height) * sqrt(CGFloat(itemViews.count))
        var itemsPerLine = ceil(items)
        
        if itemsPerLine % 2 == 0 {
            itemsPerLine++
        }
        let lines = ceil(CGFloat(itemViews.count)/itemsPerLine)
        var newMinimumZoomScale: CGFloat = 0
        
        let floatDiameter = CGFloat(itemDiameter)
        let floatPadding = CGFloat(itemPadding)
        if isContentSizeDirty {
            contentSizeUnscaled = CGSizeMake(itemsPerLine*floatDiameter+(itemsPerLine+1)*floatPadding+(floatDiameter+floatPadding)/2, lines*floatDiameter+(2)*floatPadding)
            
            newMinimumZoomScale = min((size.width-insets.left-insets.right)/contentSizeUnscaled.width,
                (size.height-insets.top-insets.bottom)/contentSizeUnscaled.height)
            
            contentSizeExtra = CGSizeMake((size.width-floatDiameter*0.5)/newMinimumZoomScale,
                (size.height-floatDiameter*0.5)/newMinimumZoomScale)
            
            contentSizeUnscaled.width += contentSizeExtra.width
            contentSizeUnscaled.height += contentSizeExtra.height
            contentView.bounds = CGRectMake(0, 0, contentSizeUnscaled.width, contentSizeUnscaled.height)
        }
        if isMinZoomLevelDirty {
            minimumZoomScale = newMinimumZoomScale
            let newZoom: CGFloat = max(zoomScale, newMinimumZoomScale)
            if newZoom != zoomScaleCache || true {
                zoomScale = newZoom
                zoomScaleCache = newZoom
                
                contentView.center = CGPointMake(contentSizeUnscaled.width*0.5*newZoom, contentSizeUnscaled.height*0.5*newZoom)
                contentSize = CGSizeMake(contentSizeUnscaled.width*newZoom, contentSizeUnscaled.height*newZoom)
            }
        }
        if isContentSizeDirty {
            var idx: UInt = 0
            for view in itemViews {
                view.bounds = CGRectMake(0, 0, floatDiameter, floatDiameter)
                
                
                var line: UInt = UInt(CGFloat(idx)/itemsPerLine)
                var indexInLine: UInt = UInt(CGFloat(idx)%itemsPerLine)
                
                if idx == 0 {
                    line = UInt(CGFloat(itemViews.count)/itemsPerLine/2)
                    indexInLine = UInt(itemsPerLine/2)
                } else {
                    if line == UInt(CGFloat(itemViews.count)/itemsPerLine/2) && indexInLine == UInt(itemsPerLine/2) {
                        line = 0
                        indexInLine = 0
                    }
                }
                
                var lineOffset: UInt = 0
                if line%2 == 1 {
                    lineOffset = (itemDiameter+itemPadding) / 2
                }
                
                let floatLine = CGFloat(line)
                let floatLineOffset = CGFloat(lineOffset)
                let floatIndexInLine = CGFloat(indexInLine)
                
                let posX: CGFloat = contentSizeExtra.width*0.5+floatPadding+floatLineOffset+floatIndexInLine*(floatDiameter + floatPadding)+floatDiameter/2
                let posY: CGFloat = contentSizeExtra.height*0.5+floatPadding+floatLine*(floatDiameter)+floatDiameter/2
                
                view.center = CGPointMake(posX, posY)
                idx++
            }
            isContentSizeDirty = false
        }
        if isMinZoomLevelDirty {
            if lastFocusedViewIndex <= UInt(itemViews.count) {
                centerOn(lastFocusedViewIndex, zoomScale: zoomScaleCache, animated: false)
                isMinZoomLevelDirty = false
            }
        }
        
        zoomScaleCache = self.zoomScale
        touchView.bounds = CGRectMake(0, 0, (contentSizeUnscaled.width - contentSizeExtra.width) * zoomScaleCache, (contentSizeUnscaled.height - contentSizeExtra.height) * zoomScaleCache)
        touchView.center = CGPointMake(contentSizeUnscaled.width * 0.5 * zoomScaleCache, contentSizeUnscaled.height * 0.5 * zoomScaleCache)
        
        let scale = min(minimumItemScaling * transformFactor + (1 - transformFactor), 1)
        minTransform = CGAffineTransformMakeScale(scale, scale)
        for view in itemViews {
            transformView(view)
        }
    }
    
    

    
    
    
}
