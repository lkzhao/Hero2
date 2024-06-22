//
//  File.swift
//
//
//  Created by Luke Zhao on 10/24/21.
//

import BaseToolbox
import UIKit

public protocol SheetBackgroundDelegate {
    func sheetTopInsetFor(sheetTransition: SheetTransition) -> CGFloat
    func sheetApplyOverlay(sheetTransition: SheetTransition) -> Bool
}

public protocol SheetForegroundDelegate {
    func canDismiss(sheetTransition: SheetTransition) -> Bool
    func didTryToDismiss(sheetTransition: SheetTransition)
    func preferredSheetSize(sheetTransition: SheetTransition, boundingSize: CGSize) -> CGSize?
}

extension UIColor {
    static let firstLevelSheetOverlay = UIColor {
        if $0.userInterfaceStyle == .dark {
            return UIColor(white: $0.userInterfaceLevel == .elevated ? 0.0 : 0.4, alpha: 0.2)
        } else {
            return UIColor(white: 0.3, alpha: 0.2)
        }
    }
    static let firstLevelFullscreenSheetOverlay = UIColor(white: 0.0, alpha: 0.35)
    static let secondLevelFullscreenSheetOverlay = UIColor(white: 0.0, alpha: 0.15)
}

class SheetPresentationController: UIPresentationController, UIGestureRecognizerDelegate {
    override var shouldRemovePresentersView: Bool {
        return false
    }
    lazy var panGR = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gr:)))

    var parentSheetPresentationController: SheetPresentationController? {
        presentingViewController.presentationController as? SheetPresentationController
    }

    var childSheetPresentationController: SheetPresentationController? {
        presentedViewController.presentedViewController?.presentationController as? SheetPresentationController
    }

    var hasChildSheet: Bool {
        childSheetPresentationController != nil
    }

    var hasParentSheet: Bool {
        parentSheetPresentationController != nil
    }

    let overlayView = UIView()
    let backgroundView = UIView()
    let touchBlockingView = UIView()
    var transition: SheetTransition!
    weak var originalSuperview: UIView?
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let container = containerView else { return }
        originalSuperview = presentingViewController.view.superview

        overlayView.zPosition = 100

        if presentingViewController.findObjectMatchType(SheetBackgroundDelegate.self)?.sheetApplyOverlay(sheetTransition: transition) != false {
            presentingViewController.view.addSubview(overlayView)
        }
        presentingViewController.view.clipsToBounds = true
        
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBackground)))
        overlayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBackground)))

        container.isUserInteractionEnabled = false
        container.addSubview(backgroundView)
        container.addSubview(presentingViewController.view)
        container.addSubview(presentedViewController.view)
        presentedViewController.view.frame = presentedViewController.sheetFrame(transition: transition, container: container)
        panGR.delegate = self
        presentedViewController.view.addGestureRecognizer(panGR)
    }
    override func presentationTransitionDidEnd(_ completed: Bool) {
        containerView?.isUserInteractionEnabled = true
        super.presentationTransitionDidEnd(completed)
        if !completed {
            overlayView.removeFromSuperview()
            if let originalSuperview = originalSuperview {
                originalSuperview.addSubview(presentingViewController.view)
            }
        }
    }
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        delay {
            // need to delay until the next run loop because the transition will be inserting the view again.
            self.containerView?.insertSubview(self.touchBlockingView, aboveSubview: self.presentingViewController.view)
        }
    }
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        touchBlockingView.removeFromSuperview()
        if completed {
            overlayView.removeFromSuperview()
            if let originalSuperview = originalSuperview {
                originalSuperview.addSubview(presentingViewController.view)
            }
        }
    }
    @objc func didTapBackground() {
        if let foregroundDelegate = presentedViewController.findObjectMatchType(SheetForegroundDelegate.self), !foregroundDelegate.canDismiss(sheetTransition: transition) {
            foregroundDelegate.didTryToDismiss(sheetTransition: transition)
            return
        }
        presentedViewController.dismiss(animated: true, completion: nil)
    }
    var backTransform: CGAffineTransform {
        guard let container = containerView, let back = presentingViewController.view else { return .identity }
        let sideInset: CGFloat = container.isIpadLayout ? 20 : 16
        let scaleSideFactor: CGFloat = sideInset / container.bounds.width
        let scale: CGFloat = 1 - scaleSideFactor * 2
        let topInset = presentingViewController.findObjectMatchType(SheetBackgroundDelegate.self)?.sheetTopInsetFor(sheetTransition: transition) ?? 0
        if container.isCompactVertical {
            return .identity
        } else if hasParentSheet {
            return .identity.translatedBy(y: -back.bounds.height * scaleSideFactor - 10).scaledBy(scale)
        } else if container.isIpadLayout {
            return .identity
        } else {
            return .identity.translatedBy(y: -container.bounds.height * scaleSideFactor + container.safeAreaInsets.top - topInset).scaledBy(scale)
        }
    }
    var thirdTransform: CGAffineTransform {
        guard let container = containerView else { return .identity }
        if (container.isIpadLayout && !hasParentSheet) || container.isCompactVertical {
            return .identity
        } else {
            return backTransform.scaledBy(0.985)
        }
    }

    func applyPresentedState() {
        guard let front = presentedViewController.view, let back = presentingViewController.view else { return }
        front.transform = .identity
        if let parentSheetPresentationController = parentSheetPresentationController {
            parentSheetPresentationController.presentingViewController.view.transform = parentSheetPresentationController.thirdTransform
        }
        back.transform = backTransform
#if !targetEnvironment(macCatalyst)
        back.cornerRadius = transition.cornerRadius
#endif
        overlayView.alpha = 1
    }

    func applyDismissedState() {
        guard let container = containerView, let front = presentedViewController.view, let back = presentingViewController.view else { return }
        front.transform = .identity.translatedBy(y: container.bounds.height)
        back.transform = .identity
        if let parentSheetPresentationController = parentSheetPresentationController {
            parentSheetPresentationController.presentingViewController.view.transform = parentSheetPresentationController.backTransform
        }
#if !targetEnvironment(macCatalyst)
        back.layer.cornerCurve = .continuous
        if hasParentSheet {
            back.cornerRadius = transition.cornerRadius
        } else {
            back.cornerRadius = transition.displayCornerRadius
        }
#endif
        overlayView.alpha = 0
    }
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        guard let container = containerView else { return }
        backgroundView.frame = container.bounds
        touchBlockingView.frame = container.bounds
        if container.isIpadLayout || container.isCompactVertical {
            overlayView.backgroundColor = hasParentSheet ? .secondLevelFullscreenSheetOverlay : .firstLevelFullscreenSheetOverlay
        } else {
            overlayView.backgroundColor = .firstLevelSheetOverlay
        }
        if hasParentSheet {
            presentingViewController.view.frameWithoutTransform = presentingViewController.sheetFrame(transition: transition, container: container)
        } else {
            presentingViewController.view.frameWithoutTransform = container.bounds
        }

        overlayView.frameWithoutTransform = presentingViewController.view.bounds

        presentedViewController.view.frameWithoutTransform = presentedViewController.sheetFrame(transition: transition, container: container)
        presentedViewController.view.cornerRadius = container.isCompactVertical ? transition.displayCornerRadius : transition.cornerRadius
        presentedViewController.view.layer.maskedCorners =
        container.isIpadLayout ? [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner] : [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        presentedViewController.view.clipsToBounds = true
        if !transition.isAnimating, !hasChildSheet {
            applyPresentedState()
        }
    }
    var childScrollView: UIScrollView? {
        guard let vc = (presentedViewController as? UINavigationController)?.topViewController else { return nil }
        return vc.view.flattendSubviews.first { view in
            if let view = view as? UIScrollView, view.isTracking, view.contentSize.inset(by: -view.adjustedContentInset).height > view.bounds.height {
                return true
            } else {
                return false
            }
        } as? UIScrollView
    }
    var startLocation: CGFloat = 0
    var lastDraggedScrollView: UIScrollView?
    var initialFractionCompleted: CGFloat = 0
    var canDismiss: Bool = true
    @objc func handlePan(gr: UIPanGestureRecognizer) {
        let v = gr.velocity(in: nil)
        let location = gr.location(in: nil).y
        switch gr.state {
        case .began, .changed:
            if gr.state == .began {
                lastDraggedScrollView = childScrollView
                lastDraggedScrollView?.disableTopBounce = true
            }
            let isDragFromHeader = gr.state == .began && location < 120
            let atTopOfScrollView = lastDraggedScrollView.map { $0.contentOffset.y <= -$0.adjustedContentInset.top } ?? true
            let isDownSwipe = v.y > abs(v.x)
            if !transition.isInteractive, isDownSwipe, atTopOfScrollView || isDragFromHeader {
                if isDragFromHeader, let lastDraggedScrollView = lastDraggedScrollView {
                    // disable current scroll session
                    lastDraggedScrollView.panGestureRecognizer.isEnabled = false
                    lastDraggedScrollView.panGestureRecognizer.isEnabled = true
                }
                startLocation = location
                if !transition.isTransitioning {
                    transition.beginInteractiveTransition()
                    canDismiss = presentedViewController.findObjectMatchType(SheetForegroundDelegate.self)?.canDismiss(sheetTransition: transition) ?? true
                    presentedViewController.dismiss(animated: true, completion: nil)
                } else {
                    transition.beginInteractiveTransition()
                }
                initialFractionCompleted = transition.fractionCompleted
            }
            if transition.isInteractive {
                let translation = location - startLocation
                var progress = translation / presentedViewController.view.frameWithoutTransform.height
                progress = transition.isPresenting != transition.isReversed ? -progress : progress
                progress = (initialFractionCompleted + progress * (canDismiss ? 1.0 : 0.1)).clamp(0, 1)
                transition.fractionCompleted = progress
            }
        default:
            lastDraggedScrollView?.disableTopBounce = false
            if transition.isInteractive {
                let translation = location - startLocation
                var progress = (v.y + translation) / presentedViewController.view.frameWithoutTransform.height
                progress = transition.isPresenting != transition.isReversed ? -progress : progress
                progress = (initialFractionCompleted + progress).clamp(0, 1)
                if progress > 0.5, !canDismiss {
                    transition.endInteractiveTransition(shouldFinish: false)
                    presentedViewController.findObjectMatchType(SheetForegroundDelegate.self)?.didTryToDismiss(sheetTransition: transition)
                } else {
                    transition.endInteractiveTransition(shouldFinish: progress > 0.5)
                }
            }
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let otherGestureRecognizer = otherGestureRecognizer as? UIPanGestureRecognizer,
            let scrollView = otherGestureRecognizer.view as? UIScrollView,
            otherGestureRecognizer.minimumNumberOfTouches <= 1,
            otherGestureRecognizer == scrollView.panGestureRecognizer,
            scrollView.isScrollEnabled,
            scrollView.contentSize.height > scrollView.bounds.inset(by: scrollView.adjustedContentInset).height
        {
            return true
        } else {
            return false
        }
    }
}

open class SheetTransition: HeroTransition {
    weak var presentationController: SheetPresentationController!
    open var cornerRadius: CGFloat = 10

    open override var automaticallyLayoutToView: Bool {
        false
    }

    open override func animate() {
        guard let presentationController = presentationController else {
            fatalError()
        }
        addPresentStateBlock {
            presentationController.applyPresentedState()
        }
        addDismissStateBlock {
            presentationController.applyDismissedState()
        }
    }

    open func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = SheetPresentationController(presentedViewController: presented, presenting: presenting)
        presentationController.transition = self
        self.presentationController = presentationController
        return presentationController
    }
    
    public var preferLightContentStatusBar: Bool {
        guard let container = presentationController?.containerView else { return false }
        return !container.isIpadLayout && !container.isCompactVertical
    }
}

private extension UIView {
    var isIpadLayout: Bool {
        bounds.width >= 512 && traitCollection.verticalSizeClass != .compact
    }
    var isCompactVertical: Bool {
        traitCollection.verticalSizeClass == .compact
    }
}

private extension UIViewController {
    func sheetFrame(transition: SheetTransition, container: UIView) -> CGRect {
        if container.isIpadLayout {
            let sheetSize = findObjectMatchType(SheetForegroundDelegate.self)?.preferredSheetSize(sheetTransition: transition, boundingSize: container.bounds.size) ?? CGSize(width: 704, height: 600)
            return CGRect(center: container.bounds.center, size: sheetSize)
        } else if container.isCompactVertical {
            return container.bounds
        } else {
            let topInset = container.safeAreaInsets.top + 10
            return CGRect(x: 0, y: topInset, width: container.bounds.width, height: container.bounds.height - topInset)
        }
    }
}

extension BaseTransition {
    private static let cornerRadiusKey: String = {
        let components = ["Radius", "Corner", "display", "_"]
        return components.reversed().joined()
    }()

    public var displayCornerRadius: CGFloat {
        #if os(iOS)
        guard let cornerRadius = UIScreen.main.value(forKey: Self.cornerRadiusKey) as? CGFloat else {
            return 0
        }

        return cornerRadius
        #else
        return 0
        #endif
    }
}
