//
//  ItemsView.swift
//  WatchSpringboard
//
//  Created by Joe Blau on 11/8/14.
//  Copyright (c) 2014 joeblau. All rights reserved.
//

import UIKit

class ItemsView: UIView {
    
    var springboardView: SpringboardView = SpringboardView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        springboardView.frame = UIScreen.mainScreen().bounds
        
        var itemViews: [SpringboardItemView] = Array<SpringboardItemView>()
        let clipPath = UIBezierPath(ovalInRect: CGRectInset(CGRectMake(0, 0, 60, 60), 0.5, 0.5))
        
        for idx in 1..<100 {
            
            let itemView = SpringboardItemView()
            let image = UIImage(named: "item")
            
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(60, 60), false, UIScreen.mainScreen().scale)
            clipPath.addClip()
            image?.drawInRect(CGRectMake(0, 0, 60, 60))
            let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            itemView.icon.image = renderedImage
            itemView.title = "Item \(idx)"
            itemViews += [itemView]
        }
        
        springboardView.itemViews = itemViews
        addSubview(springboardView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var statusFrame = CGRectMake(0, 0, 0, 0)
        if self.window != nil {
            let statusBarFrame = UIApplication.sharedApplication().statusBarFrame
            statusFrame = self.window!.convertRect(statusBarFrame, toView: self)
            
            var insets = springboardView.contentInset
            insets.top = statusFrame.size.height
            springboardView.contentInset = insets
        }
    }
    
    // MARK: - Actions
    
    func selectEmotion() {
        print("select")
    }
}
