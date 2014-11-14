//
//  ViewController.swift
//  WatchSpringboard
//
//  Created by Joe Blau on 11/14/14.
//  Copyright (c) 2014 joeblau. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override func viewWillAppear(animated: Bool) {
    
    let springboard = self.springboard()
    springboard.centerOn(0, zoomScale: 1, animated: false)
    //    springboard.doIntroAnimation()
    //    springboard.alpha = 1
    //    }
  }
  
  func customView() -> ItemsView {
    return self.view as ItemsView
  }
  
  func springboard() -> SpringboardView {
    return (self.view as ItemsView).springboardView
  }
}

