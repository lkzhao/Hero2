// Transition.swift
// Copyright © 2020 Noto. All rights reserved.

import UIKit

open class Transition: NSObject {
  public private(set) var isPresenting: Bool = true
  public private(set) var isTransitioning: Bool = false
  public private(set) var isNavigationTransition: Bool = false
  public private(set) var isInteractive = false
  public private(set) var animator: UIViewPropertyAnimator?
  public private(set) var transitionContext: UIViewControllerContextTransitioning?

  public var fractionCompleted: CGFloat {
    get { animator?.fractionComplete ?? 0 }
    set { animator?.fractionComplete = newValue }
  }
  
  public var duration: TimeInterval
  public var timingParameters: UITimingCurveProvider

  public init(duration: TimeInterval = 0.4, timingParameters: UITimingCurveProvider = UISpringTimingParameters(dampingRatio: 0.9)) {
    self.duration = duration
    self.timingParameters = timingParameters
    super.init()
  }
  
  open func beginInteractiveTransition() {
    isInteractive = true
  }
  
  open func endInteractiveTransition(shouldFinish: Bool) {
    guard isInteractive, let animator = animator else { return }
    isInteractive = false
    if shouldFinish {
      transitionContext?.finishInteractiveTransition()
    } else {
      transitionContext?.cancelInteractiveTransition()
    }

    animator.isReversed = !shouldFinish
    if animator.state == .inactive {
      animator.startAnimation()
    } else {
      animator.continueAnimation(withTimingParameters: nil, durationFactor: 1)
    }
  }
  
  // MARK: - Subclass Overrides
  open func animate() -> (dismissed: () -> Void, presented: () -> Void, completed: (Bool) -> Void) {
    return ({}, {}, { _ in })
  }
}

// MARK: - Helper Getters
extension Transition {
  public var transitionContainer: UIView? {
    return transitionContext?.containerView
  }

  public var toViewController: UIViewController? {
    return transitionContext?.viewController(forKey: .to)
  }

  public var fromViewController: UIViewController? {
    return transitionContext?.viewController(forKey: .from)
  }

  public var toView: UIView? {
    return toViewController?.view
  }

  public var fromView: UIView? {
    return fromViewController?.view
  }

  public var foregroundViewController: UIViewController? {
    return isPresenting ? toViewController : fromViewController
  }

  public var backgroundViewController: UIViewController? {
    return !isPresenting ? toViewController : fromViewController
  }

  public var foregroundView: UIView? {
    return isPresenting ? toView : fromView
  }

  public var backgroundView: UIView? {
    return !isPresenting ? toView : fromView
  }

  public var toOverFullScreen: Bool {
    return toViewController?.modalPresentationStyle == .overFullScreen
      || toViewController?.modalPresentationStyle == .overCurrentContext
  }

  public var fromOverFullScreen: Bool {
    return fromViewController?.modalPresentationStyle == .overFullScreen
      || fromViewController?.modalPresentationStyle == .overCurrentContext
  }

  public func isBackground(viewController: UIViewController) -> Bool {
    return (isPresenting && fromViewController == viewController)
      || (!isPresenting && toViewController == viewController)
  }
}

extension Transition: UIViewControllerInteractiveTransitioning {
  open func interruptibleAnimator(using _: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
    return animator!
  }
  
  open func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
    animateTransition(using: transitionContext)
  }

  open var wantsInteractiveStart: Bool {
    isInteractive
  }
}


extension Transition: UIViewControllerAnimatedTransitioning {
  open func animateTransition(using context: UIViewControllerContextTransitioning) {
    transitionContext = context
    isTransitioning = true
    
    animator = UIViewPropertyAnimator(duration: duration, timingParameters: timingParameters)

    let fullScreenSnapshot = transitionContainer?.window?.snapshotView(afterScreenUpdates: false) ?? fromView?.snapshotView(afterScreenUpdates: false)
    if let fullScreenSnapshot = fullScreenSnapshot {
      (transitionContainer?.window ?? transitionContainer)?.addSubview(fullScreenSnapshot)
    }
    func startAnimation() {
      let container = transitionContainer!
      container.isUserInteractionEnabled = false
      container.addSubview(backgroundView!)
      container.addSubview(foregroundView!)
      toView!.frame = container.frame
      toView!.layoutIfNeeded()

      let (dismissedState, presentedState, completion) = animate()
      
      if isPresenting {
        dismissedState()
        animator!.addAnimations(presentedState)
      } else {
        presentedState()
        animator!.addAnimations(dismissedState)
      }
      
      // flush the current transaction before animation start.
      // otherwise delay animation on dismiss might not be registered.
      CATransaction.flush()

      animator!.addCompletion { [weak self] pos in
        container.isUserInteractionEnabled = true
        completion(pos == .end)
        self?.completeTransition(finished: pos == .end)
      }
      
      fullScreenSnapshot?.removeFromSuperview()
      animator?.startAnimation()
      if isInteractive {
        animator?.pauseAnimation()
      }
    }

    if isNavigationTransition {
      // When animating within navigationController, we have to dispatch later into the main queue.
      // otherwise snapshots will be pure white. Possibly a bug with UIKit
      DispatchQueue.main.async {
        startAnimation()
      }
    } else {
      startAnimation()
    }
  }

  open func transitionDuration(using: UIViewControllerContextTransitioning?) -> TimeInterval {
    duration
  }

  open func completeTransition(finished: Bool) {
    if toOverFullScreen || fromOverFullScreen, let destinationView = finished ? toView : fromView {
      transitionContainer?.window?.addSubview(destinationView)
    }
    isTransitioning = false
    transitionContext?.completeTransition(finished)
  }

  open func animationEnded(_ transitionCompleted: Bool) {
    transitionContext = nil
    isTransitioning = false
    isNavigationTransition = false
  }
}

extension Transition: UIViewControllerTransitioningDelegate {
  private func setupTransition(isPresenting: Bool, isNavigationTransition: Bool) {
    self.isPresenting = isPresenting
    self.isNavigationTransition = isNavigationTransition
    self.isTransitioning = true
  }
  
  var interactiveTransitioning: UIViewControllerInteractiveTransitioning? {
    return self
  }

  public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    setupTransition(isPresenting: true, isNavigationTransition: false)
    return self
  }

  public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    setupTransition(isPresenting: false, isNavigationTransition: false)
    return self
  }

  public func interactionControllerForDismissal(using _: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    return interactiveTransitioning
  }

  public func interactionControllerForPresentation(using _: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    return interactiveTransitioning
  }
}

extension Transition: UINavigationControllerDelegate {
  public func navigationController(_: UINavigationController, interactionControllerFor _: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    return interactiveTransitioning
  }

  public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//    navigationController.view.layoutIfNeeded()
    setupTransition(isPresenting: operation == .push, isNavigationTransition: true)
    return self
  }
}
