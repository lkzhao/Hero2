// Transition.swift
// Copyright © 2020 Noto. All rights reserved.

import UIKit

open class Transition: NSObject {
    public private(set) var isPresenting: Bool = true
    public private(set) var isInteractive = false
    public private(set) var animator: UIViewPropertyAnimator?
    public private(set) weak var navigationController: UINavigationController?
    public private(set) var transitionContext: UIViewControllerContextTransitioning?
    public private(set) var isTransitioning: Bool = false
    public var isAnimating: Bool = false

    public var isUserInteractionEnabled = false
    
    public var duration: TimeInterval
    public var timingParameters: UITimingCurveProvider

    public var isReversed: Bool {
        animator?.isReversed ?? false
    }

    open var automaticallyLayoutToView: Bool {
        true
    }

    public var fractionCompleted: CGFloat {
        get { animator?.fractionComplete ?? 0 }
        set {
            guard let animator = animator, animator.state == .active else { return }
            animator.fractionComplete = newValue
        }
    }

    private var canAddBlocks: Bool = false
    private var dismissBlocks: [() -> Void] = []
    private var presentBlocks: [() -> Void] = []
    private var completeBlocks: [(Bool) -> Void] = []
    private var prepareBlocks: [() -> Void] = []
    private var pausedAnimations: [UIView: [String: CAAnimation]] = [:]
    public func pause(view: UIView, animationForKey key: String) {
        guard pausedAnimations[view]?[key] == nil, let anim = view.layer.animation(forKey: key) else { return }
        pausedAnimations[view, default: [:]][key] = anim
        view.layer.removeAnimation(forKey: key)
    }

    #if targetEnvironment(simulator)
        public static var defaultDuration: TimeInterval = 0.4 * TimeInterval(UIAnimationDragCoefficient())
    #else
        public static var defaultDuration: TimeInterval = 0.4
    #endif
    public static var defaultTimingParameters: UITimingCurveProvider = UISpringTimingParameters(dampingRatio: 0.95)
    public init(
        duration: TimeInterval = defaultDuration,
        timingParameters: UITimingCurveProvider = defaultTimingParameters
    ) {
        self.duration = duration
        self.timingParameters = timingParameters
        super.init()
    }

    open func beginInteractiveTransition() {
        isInteractive = true
        isTransitioning = true

        animator?.pauseAnimation()
        transitionContext?.pauseInteractiveTransition()
    }

    open func endInteractiveTransition(shouldFinish: Bool) {
        guard isInteractive else { return }
        for (view, animations) in pausedAnimations {
            for (key, anim) in animations {
                view.layer.add(anim, forKey: key)
            }
        }
        pausedAnimations.removeAll()
        isInteractive = false
        if shouldFinish {
            transitionContext?.finishInteractiveTransition()
        } else {
            transitionContext?.cancelInteractiveTransition()
        }

        if let animator = animator {
            animator.isReversed = !shouldFinish
            if animator.state == .inactive {
                animator.startAnimation()
            } else {
                animator.continueAnimation(withTimingParameters: nil, durationFactor: 1)
            }
        }
    }

    public func addDismissStateBlock(_ block: @escaping () -> Void) {
        assert(canAddBlocks, "Should only add block during the animate() method")
        dismissBlocks.append(block)
    }

    public func addPresentStateBlock(_ block: @escaping () -> Void) {
        assert(canAddBlocks, "Should only add block during the animate() method")
        presentBlocks.append(block)
    }

    public func addCompletionBlock(_ block: @escaping (Bool) -> Void) {
        assert(canAddBlocks, "Should only add block during the animate() method")
        completeBlocks.append(block)
    }
    
    public func addPrepareBlock(_ block: @escaping () -> Void) {
        prepareBlocks.append(block)
    }

    // MARK: - Subclass Overrides
    open func animate() {}
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
        pausedAnimations.removeAll()

        animator = UIViewPropertyAnimator(duration: duration, timingParameters: timingParameters)

        func startAnimation() {
            for prepareBlock in prepareBlocks {
                prepareBlock()
            }
            prepareBlocks.removeAll()

            let container = transitionContainer!
            if !isUserInteractionEnabled {
                container.isUserInteractionEnabled = isUserInteractionEnabled
            }
            container.addSubview(backgroundView!)
            container.addSubview(foregroundView!)
            if automaticallyLayoutToView {
                toView!.frameWithoutTransform = container.frame
                toView!.layoutIfNeeded()
            }
            
            isAnimating = true

            canAddBlocks = true
            animate()
            canAddBlocks = false

            let dismissedState = { [dismissBlocks] in
                for block in dismissBlocks {
                    block()
                }
            }

            let presentedState = { [presentBlocks] in
                for block in presentBlocks {
                    block()
                }
            }

            let completion = { [completeBlocks] (finished: Bool) in
                for block in completeBlocks {
                    block(finished)
                }
            }
            dismissBlocks = []
            presentBlocks = []
            completeBlocks = []

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

            animator!
                .addCompletion { [weak self] pos in
                    container.isUserInteractionEnabled = true
                    completion(pos == .end)
                    self?.completeTransition(finished: pos == .end)
                }

            animator?.startAnimation()
            if isInteractive {
                animator?.pauseAnimation()
            }
        }

        if navigationController != nil {
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
            transitionContainerSuperview.addSubview(toView)  // UIKit will remove the entire transitionContainer when fromOverFullscreen is set. We need to manually add it back.
        } else {
            transitionContext?.completeTransition(finished)
        }
    }

    open func animationEnded(_ transitionCompleted: Bool) {
        pausedAnimations.removeAll()
        transitionContext = nil
        animator = nil
        isAnimating = false
        navigationController = nil
        isTransitioning = false
        isInteractive = false
    }
}

extension Transition: UIViewControllerTransitioningDelegate {
    @discardableResult internal func setupTransition(isPresenting: Bool, navigationController: UINavigationController? = nil) -> Self {
        self.isPresenting = isPresenting
        self.isTransitioning = true
        self.navigationController = navigationController
        return self
    }

    private var interactiveTransitioning: UIViewControllerInteractiveTransitioning? {
        self
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        setupTransition(isPresenting: true)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        setupTransition(isPresenting: false)
    }

    public func interactionControllerForDismissal(using _: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        interactiveTransitioning
    }

    public func interactionControllerForPresentation(using _: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        interactiveTransitioning
    }
}

extension Transition: UINavigationControllerDelegate {
    public func navigationController(_: UINavigationController, interactionControllerFor _: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        interactiveTransitioning
    }

    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        setupTransition(isPresenting: operation == .push, navigationController: navigationController)
    }
}
