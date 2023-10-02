//
//  File.swift
//
//
//  Created by Luke Zhao on 10/24/21.
//

import BaseToolbox
import ScreenCorners
import UIKit

public protocol MatchTransitionDelegate {
    func matchedViewFor(transition: MatchModalTransition, otherViewController: UIViewController) -> UIView?
}

open class MatchModalTransition: Transition {
    let foregroundContainerView = UIView()
    var isMatched = false

    public var transitionVertically = false
    open var canDismissVertically = true
    open var canDismissHorizontally = true
    open var automaticallyAddDismissGestureRecognizer: Bool = true
    open lazy var dismissGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gr:))).then {
        $0.delegate = self
        if #available(iOS 13.4, *) {
            $0.allowedScrollTypesMask = .all
        }
    }

    open override func animate() {
        guard let back = backgroundView, let front = foregroundView, let container = transitionContainer else {
            fatalError()
        }
        let matchedDestinationView = foregroundViewController?.findObjectMatchType(MatchTransitionDelegate.self)?
            .matchedViewFor(transition: self, otherViewController: backgroundViewController!)
        let matchedSourceView = backgroundViewController?.findObjectMatchType(MatchTransitionDelegate.self)?
            .matchedViewFor(transition: self, otherViewController: foregroundViewController!)

        let isFullScreen = container.window?.convert(container.bounds, from: container) == container.window?.bounds
        let foregroundContainerView = self.foregroundContainerView
        let finalCornerRadius: CGFloat = isFullScreen ? UIScreen.main.displayCornerRadius : foregroundContainerView.cornerRadius
        foregroundContainerView.autoresizingMask = []
        foregroundContainerView.autoresizesSubviews = false
        foregroundContainerView.cornerRadius = finalCornerRadius
        foregroundContainerView.clipsToBounds = true
        foregroundContainerView.frame = container.bounds
        foregroundContainerView.backgroundColor = front.backgroundColor
        container.addSubview(foregroundContainerView)
        foregroundContainerView.addSubview(front)
        let defaultDismissedFrame =
            transitionVertically ? container.bounds.offsetBy(dx: 0, dy: container.bounds.height) : container.bounds.offsetBy(dx: container.bounds.width, dy: 0)
        let dismissedFrame =
            matchedSourceView.map {
                container.convert($0.bounds, from: $0)
            } ?? defaultDismissedFrame
        let presentedFrame =
            matchedDestinationView.map {
                container.convert($0.bounds, from: $0)
            } ?? container.bounds

        back.addOverlayView()
        let sourceViewPlaceholder = UIView()
        if let matchedSourceView = matchedSourceView {
            matchedSourceView.superview?.insertSubview(sourceViewPlaceholder, aboveSubview: matchedSourceView)
            foregroundContainerView.addSubview(matchedSourceView)
        }
        isMatched = matchedSourceView != nil

        addDismissStateBlock {
            foregroundContainerView.cornerRadius = matchedSourceView?.cornerRadius ?? 0
            foregroundContainerView.frameWithoutTransform = dismissedFrame
            if let matchedSourceView = matchedSourceView {
                let scaledSize = presentedFrame.size.size(fill: dismissedFrame.size)
                let scale = scaledSize.width / container.bounds.width
                let sizeOffset = -(scaledSize - dismissedFrame.size) / 2
                let originOffset = -presentedFrame.minY * scale
                let offsetX = -(1 - scale) / 2 * container.bounds.width
                let offsetY = -(1 - scale) / 2 * container.bounds.height
                front.transform = .identity
                    .translatedBy(
                        x: offsetX + sizeOffset.width,
                        y: offsetY + sizeOffset.height + originOffset
                    )
                    .scaledBy(scale)
                matchedSourceView.frameWithoutTransform = dismissedFrame.bounds
                matchedSourceView.alpha = 1
            }
            back.overlayView?.backgroundColor = .clear
        }
        addPresentStateBlock {
            foregroundContainerView.cornerRadius = finalCornerRadius
            foregroundContainerView.frameWithoutTransform = container.bounds
            front.transform = .identity
            matchedSourceView?.frameWithoutTransform = presentedFrame
            matchedSourceView?.alpha = 0
            back.overlayView?.backgroundColor = .black.withAlphaComponent(0.5)
        }
        addCompletionBlock { _ in
            back.removeOverlayView()
            container.addSubview(front)
            if let sourceSuperView = sourceViewPlaceholder.superview,
                sourceSuperView != container,
                let matchedSourceView = matchedSourceView
            {
                matchedSourceView.frameWithoutTransform = sourceSuperView.convert(dismissedFrame, from: container)
                sourceViewPlaceholder.superview?.insertSubview(matchedSourceView, belowSubview: sourceViewPlaceholder)
            }
            matchedSourceView?.alpha = 1
            sourceViewPlaceholder.removeFromSuperview()
            foregroundContainerView.removeFromSuperview()
        }
        addStartBlock {
            if self.isInteractive, self.isMatched {
                self.pauseForegroundView()
            }
        }
    }

    func pauseForegroundView() {
        let position = foregroundContainerView.layer.presentation()?.position ?? foregroundContainerView.layer.position
        self.pause(view: foregroundContainerView, animationForKey: "position")
        foregroundContainerView.layer.position = position
    }

    open override func animationEnded(_ transitionCompleted: Bool) {
        if isPresenting, transitionCompleted, automaticallyAddDismissGestureRecognizer {
            foregroundView?.addGestureRecognizer(dismissGestureRecognizer)
        }
        isMatched = false
        transitionVertically = false
        super.animationEnded(transitionCompleted)
    }

    var accumulatedProgress: CGFloat = 0
    @objc func handlePan(gr: UIPanGestureRecognizer) {
        guard let view = gr.view else { return }
        func progressFrom(offset: CGPoint) -> CGFloat {
            let progress = (offset.x + offset.y) / ((view.bounds.height + view.bounds.width) / 4)
            return isPresenting ? -progress : progress
        }
        switch gr.state {
        case .began:
            if !isTransitioning {
                beginInteractiveTransition()
                view.dismiss()
            } else {
                beginInteractiveTransition()
                pause(view: foregroundContainerView, animationForKey: "position")
            }
            accumulatedProgress = 0
        case .changed:
            let translation = gr.translation(in: nil)
            gr.setTranslation(.zero, in: nil)
            if isMatched {
                let progress = progressFrom(offset: translation)
                foregroundContainerView.center = foregroundContainerView.center + translation * 0.5
                fractionCompleted = (fractionCompleted + progress * 0.1).clamp(0, 1)
                accumulatedProgress += progress
            } else {
                let progress = transitionVertically ? translation.y / view.bounds.height : translation.x / view.bounds.width
                fractionCompleted = (fractionCompleted + progress).clamp(0, 1)
                accumulatedProgress += progress
            }
        default:
            let progress = accumulatedProgress + progressFrom(offset: gr.velocity(in: nil)) * 0.3
            let shouldFinish = progress > 0.5
            if isPresenting != shouldFinish {
                foregroundContainerView.isUserInteractionEnabled = false
                backgroundView?.overlayView?.isUserInteractionEnabled = false
            }
            endInteractiveTransition(shouldFinish: shouldFinish)
        }
    }
}

extension MatchModalTransition: UIGestureRecognizerDelegate {
    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer.view?.canBeDismissed == true else { return false }
        let velocity = dismissGestureRecognizer.velocity(in: nil)
        let horizontal = canDismissHorizontally && velocity.x > abs(velocity.y)
        let vertical = canDismissVertically && velocity.y > abs(velocity.x)
        transitionVertically = vertical
        // only allow right and down swipe
        return horizontal || vertical
    }

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UIPanGestureRecognizer, let scrollView = otherGestureRecognizer.view as? UIScrollView, otherGestureRecognizer == scrollView.panGestureRecognizer {
            return scrollView.contentSize.width > scrollView.bounds.width
                ? scrollView.contentOffset.x <= -scrollView.adjustedContentInset.left : scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top
        }
        return false
    }
}
