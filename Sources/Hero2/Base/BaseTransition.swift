// BaseTransition.swift
// Copyright © 2020 Noto. All rights reserved.

import UIKit

extension Notification.Name {
    public static let transitionDidUpdateIsAnimating = Notification.Name("transitionDidUpdateIsAnimating")
}

open class BaseTransition: NSObject {
    public static var animatingTransitionCount: Int = 0
    public private(set) var isPresenting: Bool = true
    public private(set) var isInteractive = false
    public private(set) var animator: UIViewPropertyAnimator
    public private(set) weak var navigationController: UINavigationController?
    public private(set) var transitionContext: UIViewControllerContextTransitioning?
    public private(set) var isTransitioning: Bool = false
    public var isAnimating: Bool = false {
        didSet {
            guard isAnimating != oldValue else { return }
            Self.animatingTransitionCount += isAnimating ? 1 : -1
            assert(Self.animatingTransitionCount >= 0)
            NotificationCenter.default.post(name: .transitionDidUpdateIsAnimating, object: nil, userInfo: ["transition": self, "isAnimating": isAnimating])
        }
    }

    public var isUserInteractionEnabled = false
    
    public var duration: TimeInterval
    public var timingParameters: UITimingCurveProvider

    public var isReversed: Bool {
        animator.isReversed
    }

    open var automaticallyLayoutToView: Bool {
        true
    }

    public var fractionCompleted: CGFloat {
        get { animator.fractionComplete }
        set {
            guard animator.state == .active else { return }
            animator.fractionComplete = newValue
        }
    }

    private var canAddBlocks: Bool = false
    private var dismissBlocks: [() -> Void] = []
    private var presentBlocks: [() -> Void] = []
    private var startBlocks: [() -> Void] = []
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
        self.animator = UIViewPropertyAnimator(duration: duration, timingParameters: timingParameters)
        super.init()
    }

    open func beginInteractiveTransition() {
        isInteractive = true
        isTransitioning = true

        animator.pauseAnimation()
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

        animator.isReversed = !shouldFinish
        if animator.state == .inactive {
            animator.startAnimation()
        } else {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 1)
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
        completeBlocks.append(block)
    }
    
    public func addPrepareBlock(_ block: @escaping () -> Void) {
        prepareBlocks.append(block)
    }

    public func addStartBlock(_ block: @escaping () -> Void) {
        startBlocks.append(block)
    }

    // MARK: - Subclass Overrides
    open func animate() {}
}

// MARK: - Helper Getters
extension BaseTransition {
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

extension BaseTransition: UIViewControllerInteractiveTransitioning {
    open func interruptibleAnimator(using _: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        animator
    }

    open func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        animateTransition(using: transitionContext)
    }

    open var wantsInteractiveStart: Bool {
        isInteractive
    }
}

extension BaseTransition: UIViewControllerAnimatedTransitioning {
    open func animateTransition(using context: UIViewControllerContextTransitioning) {
        transitionContext = context
        pausedAnimations.removeAll()

        animator = UIViewPropertyAnimator(duration: duration, timingParameters: timingParameters)

        func startAnimation() {
            for prepareBlock in prepareBlocks {
                prepareBlock()
            }
            prepareBlocks.removeAll()

            if let container = transitionContainer {
                if !isUserInteractionEnabled {
                    container.isUserInteractionEnabled = isUserInteractionEnabled
                }
                if let backgroundView {
                    container.addSubview(backgroundView)
                }
                if let foregroundView {
                    container.addSubview(foregroundView)
                }
                if automaticallyLayoutToView {
                    if !isPresenting {
                        toViewController?.presentationController?.containerViewWillLayoutSubviews()
                        container.layoutSubviews()
                        toViewController?.presentationController?.containerViewDidLayoutSubviews()
                    } else {
                        toView?.frameWithoutTransform = container.frame
                    }
                    toView?.layoutIfNeeded()
                }
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
                animator.addAnimations(presentedState)
            } else {
                presentedState()
                animator.addAnimations(dismissedState)
            }

            // flush the current transaction before animation start.
            // otherwise delay animation on dismiss might not be registered.
            CATransaction.flush()

            animator
                .addCompletion { [weak self] pos in
                    self?.transitionContainer?.isUserInteractionEnabled = true
                    completion(pos == .end)
                    self?.completeTransition(finished: pos == .end)
                }

            animator.startAnimation()

            for block in startBlocks {
                block()
            }
            startBlocks = []

            if isInteractive {
                animator.pauseAnimation()
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

    @objc open func completeTransition(finished: Bool) {
        if finished {
            if !toOverFullScreen {
                fromView?.removeFromSuperview()
            }
        } else {
            if !fromOverFullScreen {
                toView?.removeFromSuperview()
            }
        }
        if automaticallyLayoutToView, let container = transitionContainer, toView?.frame != container.bounds {
            toView?.frameWithoutTransform = container.bounds
        }
        if !isPresenting, finished, let toView = toView {
            let presentationController = toView.parentViewController?.presentationController
            let containerView = presentationController?.containerView ?? (fromOverFullScreen ? transitionContainer?.superview : nil)
            transitionContext?.completeTransition(finished)
            // UIKit will remove the view from the view hierarchy for custom presentation controller. We need to manually add it back.
            containerView?.addSubview(toView)
            containerView?.setNeedsLayout()
        } else {
            transitionContext?.completeTransition(finished)
        }
    }

    open func animationEnded(_ transitionCompleted: Bool) {
        pausedAnimations.removeAll()
        transitionContext = nil
        navigationController = nil
        isTransitioning = false
        isInteractive = false
        isAnimating = false
    }
}

extension BaseTransition: UIViewControllerTransitioningDelegate {
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

extension BaseTransition: UINavigationControllerDelegate {
    public func navigationController(_: UINavigationController, interactionControllerFor _: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        interactiveTransitioning
    }

    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        setupTransition(isPresenting: operation == .push, navigationController: navigationController)
    }
}
