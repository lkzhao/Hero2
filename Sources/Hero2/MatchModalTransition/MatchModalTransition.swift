//
//  File.swift
//
//
//  Created by Luke Zhao on 10/24/21.
//

import UIKit
import ScreenCorners
import BaseToolbox

public protocol Matchable {
  func matchedViewFor(transition: MatchModalTransition, otherViewController: UIViewController) -> UIView?
}

public class MatchModalTransition: Transition {
  public override func animate() {
    guard let back = backgroundView, let front = foregroundView, let container = transitionContainer else {
      fatalError()
    }
    let matchDestination = findMatchable(viewController: foregroundViewController!)
    let matchSource = findMatchable(viewController: backgroundViewController!)
    let matchedDestinationView = matchDestination?.matchedViewFor(transition: self, otherViewController: backgroundViewController!)
    let matchedSourceView = matchSource?.matchedViewFor(transition: self, otherViewController: foregroundViewController!)

    let foregroundContainerView = UIView()
    foregroundContainerView.autoresizesSubviews = false
    foregroundContainerView.cornerRadius = UIScreen.main.displayCornerRadius
    foregroundContainerView.clipsToBounds = true
    foregroundContainerView.frame = container.bounds
    container.addSubview(foregroundContainerView)
    foregroundContainerView.addSubview(front)
    foregroundContainerView.backgroundColor = .red
    let dismissedFrame = matchedSourceView.map {
      container.convert($0.bounds, from: $0)
    } ?? container.bounds.insetBy(dx: 30, dy: 30)
    let presentedFrame = matchedDestinationView.map {
      container.convert($0.bounds, from: $0)
    } ?? container.bounds
    
    back.addOverlayView()

    addDismissStateBlock {
      foregroundContainerView.cornerRadius = 0
      foregroundContainerView.frameWithoutTransform = dismissedFrame
      let scaledSize = presentedFrame.size.size(fill: dismissedFrame.size)
      let scale = scaledSize.width / container.bounds.width
      let sizeOffset = -(scaledSize - dismissedFrame.size) / 2
      let originOffset = -presentedFrame.minY * scale
      let offsetX = -(1 - scale) / 2 * container.bounds.width
      let offsetY = -(1 - scale) / 2 * container.bounds.height
      front.transform = .identity
        .translatedBy(x: offsetX + sizeOffset.width,
                      y: offsetY + sizeOffset.height + originOffset)
        .scaledBy(scale)
      
      back.overlayView?.backgroundColor = .clear
    }
    addPresentStateBlock {
      foregroundContainerView.cornerRadius = UIScreen.main.displayCornerRadius
      foregroundContainerView.frameWithoutTransform = container.bounds
      front.transform = .identity
      back.overlayView?.backgroundColor = .black.withAlphaComponent(0.4)
    }
    addCompletionBlock { _ in
      back.removeOverlayView()
      container.addSubview(front)
      foregroundContainerView.removeFromSuperview()
    }
  }

  func findMatchable(viewController: UIViewController) -> Matchable? {
    if let viewController = viewController as? Matchable {
      return viewController
    } else {
      for child in viewController.children {
        if let matchable = findMatchable(viewController: child) {
          return matchable
        }
      }
    }
    return nil
  }
}
