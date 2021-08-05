//
//  File.swift
//  
//
//  Created by Luke Zhao on 7/30/21.
//

import UIKit

class OverlayView: UIView {}

extension UIView {
  var overlayView: OverlayView? {
    subviews.last { $0 is OverlayView } as? OverlayView
  }
  
  func addOverlayView() {
    guard overlayView == nil else { return }
    let overlayView = OverlayView(frame: bounds)
    overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    overlayView.layer.zPosition = 1000
    addSubview(overlayView)
  }
  
  func removeOverlayView() {
    overlayView?.removeFromSuperview()
  }
}
