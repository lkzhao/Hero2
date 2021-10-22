// Transition.swift
// Copyright © 2020 Noto. All rights reserved.

import UIKit

open class Transition: NSObject {
  public private(set) var isPresenting: Bool = true
  public private(set) var isNavigationTransition: Bool = false
  public private(set) var isInteractive = false
  public private(set) var animator: UIViewPropertyAnimator?
  public private(set) var transitionContext: UIViewControllerContextTransitioning?
  public var isTransitioning: Bool {
    animator != nil
  }

  public var isUserInteractionEnabled = false

  public var duration: TimeInterval
  public var timingParameters: UITimingCurveProvider

  public var isReversed: Bool {
    animator?.isReversed ?? false
  }

  public var fractionCompleted: CGFloat {
    get { animator?.fractionComplete ?? 0 }
    set {
      guard let animator = animator, animator.state == .active else { return }
      animator.fractionComplete = newValue
    }
  }

#if targetEnvironment(simulator)
  public static var defaultDuration: TimeInterval = 0.4 * TimeInterval(UIAnimationDragCoefficient())
#else
  public static var defaultDuration: TimeInterval = 0.4
#endif
  public init(
    duration: TimeInterval = defaultDuration, timingParameters: UITimingCurveProvider = UISpringTimingParameters(dampingRatio: 0.9)
  ) {
    self.duration = duration
    self.timingParameters = timingParameters
    super.init()
  }

  open func beginInteractiveTransition() {
    isInteractive = true

    animator?.pauseAnimation()
    transitionContext?.pauseInteractiveTransition()
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
      if fractionCompleted >= 0.99 {
        animator.stopAnimation(false)
        animator.finishAnimation(at: shouldFinish ? .end : .start)
      } else {
        animator.continueAnimation(withTimingParameters: nil, durationFactor: 1)
      }
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
    transitionContext?.containerView
  }

  public var toViewController: UIViewController? {
    transitionContext?.viewController(forKey: .to)
  }

  public var fromViewController: UIViewController? {
    transitionContext?.viewController(forKey: .from)
  }

  public var toView: UIView? {
    toViewController?.view
  }

  public var fromView: UIView? {
    fromViewController?.view
  }

  public var foregroundViewController: UIViewController? {
    isPresenting ? toViewController : fromViewController
  }

  public var backgroundViewController: UIViewController? {
    !isPresenting ? toViewController : fromViewController
  }

  public var foregroundView: UIView? {
    isPresenting ? toView : fromView
  }

  public var backgroundView: UIView? {
    !isPresenting ? toView : fromView
  }

  public var toOverFullScreen: Bool {
    toViewController?.modalPresentationStyle == .overFullScreen
      || toViewController?.modalPresentationStyle == .overCurrentContext
      || toViewController?.modalPresentationStyle == .custom
  }

  public var fromOverFullScreen: Bool {
    fromViewController?.modalPresentationStyle == .overFullScreen
      || fromViewController?.modalPresentationStyle == .overCurrentContext
      || fromViewController?.modalPresentationStyle == .custom
  }

  public func isBackground(viewController: UIViewController) -> Bool {
    (isPresenting && fromViewController == viewController) || (!isPresenting && toViewController == viewController)
  }
}

extension Transition: UIViewControllerInteractiveTransitioning {
  open func interruptibleAnimator(using _: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
    animator!
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

    let fullScreenSnapshot =
      transitionContainer?.window?.snapshotView(afterScreenUpdates: false)
      ?? fromView?.snapshotView(afterScreenUpdates: false)
    if let fullScreenSnapshot = fullScreenSnapshot {
      (transitionContainer?.window ?? transitionContainer)?.addSubview(fullScreenSnapshot)
    }

    let container = transitionContainer!
    container.addSubview(backgroundView!)
    container.addSubview(foregroundView!)
    toView!.frameWithoutTransform = container.frame
    toView!.layoutIfNeeded()

    // Allows the ViewControllers to load their views, and setup the transition during viewDidLoad
    container.isUserInteractionEnabled = isUserInteractionEnabled
    animator = UIViewPropertyAnimator(duration: duration, timingParameters: timingParameters)

    func startAnimation() {
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
    if finished {
      if !toOverFullScreen {
        fromView?.removeFromSuperview()
      }
    } else {
      if !fromOverFullScreen {
        toView?.removeFromSuperview()
      }
    }
    if !isPresenting, fromOverFullScreen, finished, let toView = toView, let transitionContainerSuperview = transitionContainer?.superview {
      transitionContext?.completeTransition(finished)
      transitionContainerSuperview.addSubview(toView) // UIKit will remove the entire transitionContainer when fromOverFullscreen is set. We need to manually add it back.
    } else {
      transitionContext?.completeTransition(finished)
    }
  }

  open func animationEnded(_ transitionCompleted: Bool) {
    transitionContext = nil
    animator = nil
    isNavigationTransition = false
  }
}

extension Transition: UIViewControllerTransitioningDelegate {
  @discardableResult internal func setupTransition(isPresenting: Bool, isNavigationTransition: Bool) -> Self {
    self.isPresenting = isPresenting
    self.isNavigationTransition = isNavigationTransition
    return self
  }

  private var interactiveTransitioning: UIViewControllerInteractiveTransitioning? {
    self
  }

  public func animationController(
    forPresented presented: UIViewController, presenting: UIViewController, source _: UIViewController
  ) -> UIViewControllerAnimatedTransitioning? {
    setupTransition(isPresenting: true, isNavigationTransition: false)
  }

  public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    setupTransition(isPresenting: false, isNavigationTransition: false)
  }

  public func interactionControllerForDismissal(using _: UIViewControllerAnimatedTransitioning)
    -> UIViewControllerInteractiveTransitioning?
  {
    interactiveTransitioning
  }

  public func interactionControllerForPresentation(using _: UIViewControllerAnimatedTransitioning)
    -> UIViewControllerInteractiveTransitioning?
  {
    interactiveTransitioning
  }
}

extension Transition: UINavigationControllerDelegate {
  public func navigationController(
    _: UINavigationController, interactionControllerFor _: UIViewControllerAnimatedTransitioning
  ) -> UIViewControllerInteractiveTransitioning? {
    interactiveTransitioning
  }

  public func navigationController(
    _ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation,
    from: UIViewController, to: UIViewController
  ) -> UIViewControllerAnimatedTransitioning? {
    setupTransition(isPresenting: operation == .push, isNavigationTransition: true)
  }
}
