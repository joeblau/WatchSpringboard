//
//  ItemsView.swift
//  WatchSpringboard
//
//  Created by Joe Blau on 11/8/14.
//  Copyright (c) 2014 joeblau. All rights reserved.
//

import UIKit

class ItemsView: UIView {

  let springboardView: SpringboardView!
  
  func selectEmotion() {
    println("select")
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    let fullFrame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)
    let mask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
    
    // Add Background
    springboardView = SpringboardView(frame: fullFrame)
    springboardView.autoresizingMask = mask
    
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
  
}
