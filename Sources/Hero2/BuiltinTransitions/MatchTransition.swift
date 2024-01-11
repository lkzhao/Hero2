//
//  File.swift
//
//
//  Created by Luke Zhao on 10/24/21.
//

import BaseToolbox
import ScreenCorners
import UIKit

/// Foreground ViewController and Background ViewController can implement this protocol to provide
/// a matching view for the transition to animate. This can also be implemented on the View level.
public protocol MatchTransitionDelegate {
    /// Provide the matched view from the current object's own view hierarchy for the match transition
    func matchedViewFor(transition: MatchTransition, otherViewController: UIViewController) -> UIView?
}

public struct MatchTransitionOptions {
    /// Allow the transition to dismiss vertically via its `dismissGestureRecognizer`
    public var canDismissVertically = true

    /// Allow the transition to dismiss horizontally via its `dismissGestureRecognizer`
    public var canDismissHorizontally = true

    /// If `true`, the `dismissGestureRecognizer` will be automatically added to the foreground view during presentation
    public var automaticallyAddDismissGestureRecognizer: Bool = true

    /// How much the foreground container moves when user drag across screen. This can be any value above or equal to 0.
    /// Default is 0.5, which means when user drag across the screen from left to right, the container move 50% of the screen.
    public var dragTranslationFactor: CGPoint = CGPoint(x: 0.5, y: 0.5)

    public var onDragStart: ((MatchTransition) -> ())?
}

/// A Transition that matches two items and transitions between them.
///
/// The foreground view will be masked to the item and expand as the transition
/// progress. This transition is interruptible if `isUserInteractionEnabled` is set to true.
///
open class MatchTransition: Transition {
    /// Global transition options
    public static var defaultOptions = MatchTransitionOptions()

    /// Transition options
    open var options = MatchTransition.defaultOptions

    /// Dismiss gesture recognizer, add this to your view to support drag to dismiss
    open lazy var dismissGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gr:))).then {
        $0.delegate = self
        if #available(iOS 13.4, *) {
            $0.allowedScrollTypesMask = .all
        }
    }

    private let foregroundContainerView = MatchTransitionContainerView()
    private var isMatched = false
    private(set) open var isTransitioningVertically = false

    open override func animate() {
        guard let back = backgroundView, let front = foregroundView, let container = transitionContainer else {
            fatalError()
        }

        let matchedDestinationView = foregroundViewController?.findObjectMatchType(MatchTransitionDelegate.self)?
            .matchedViewFor(transition: self, otherViewController: backgroundViewController!)
        let matchedSourceView = backgroundViewController?.findObjectMatchType(MatchTransitionDelegate.self)?
            .matchedViewFor(transition: self, otherViewController: foregroundViewController!)

        isMatched = matchedSourceView != nil

        if isPresenting {
            if options.automaticallyAddDismissGestureRecognizer {
                front.addGestureRecognizer(dismissGestureRecognizer)
            }
        }

        let isFullScreen = container.window?.convert(container.bounds, from: container) == container.window?.bounds
        let foregroundContainerView = self.foregroundContainerView
        let finalCornerRadius: CGFloat = isFullScreen ? displayCornerRadius : 0
        foregroundContainerView.cornerRadius = finalCornerRadius
        foregroundContainerView.frame = container.bounds
        foregroundContainerView.backgroundColor = front.backgroundColor
        foregroundContainerView.shadowColor = .black
        container.addSubview(foregroundContainerView)
        foregroundContainerView.contentView.addSubview(front)

        let defaultDismissedFrame =
            isTransitioningVertically ? container.bounds.offsetBy(dx: 0, dy: container.bounds.height) : container.bounds.offsetBy(dx: container.bounds.width, dy: 0)
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
            foregroundContainerView.contentView.addSubview(matchedSourceView)
        }

        addDismissStateBlock {
            foregroundContainerView.cornerRadius = matchedSourceView?.cornerRadius ?? 0
            foregroundContainerView.frameWithoutTransform = dismissedFrame

            // UIKit Bug: If we add a shadowPath animation, when the UIViewPropertyAnimator pauses,
            // the animation will jump directly to the end. fractionCompleted value seem to be messed up.
            // commenting out this line until it gets fixed.
            //
            // foregroundContainerView.recalculateShadowPath()

            foregroundContainerView.shadowOpacity = 0.0
            foregroundContainerView.shadowRadius = 8
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

            // UIKit Bug: If we add a shadowPath animation, when the UIViewPropertyAnimator pauses,
            // the animation will jump directly to the end. fractionCompleted value seem to be messed up.
            // commenting out this line until it gets fixed.
            //
            // foregroundContainerView.recalculateShadowPath()

            foregroundContainerView.shadowOpacity = 0.4
            foregroundContainerView.shadowRadius = 32
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

    open override func animationEnded(_ transitionCompleted: Bool) {
        isMatched = false
        isTransitioningVertically = false
        super.animationEnded(transitionCompleted)
    }

    func pauseForegroundView() {
        let position = foregroundContainerView.layer.presentation()?.position ?? foregroundContainerView.layer.position
        self.pause(view: foregroundContainerView, animationForKey: "position")
        foregroundContainerView.layer.position = position
    }

    var totalTranslation: CGPoint = .zero
    @objc func handlePan(gr: UIPanGestureRecognizer) {
        guard let view = gr.view else { return }
        func progressFrom(offset: CGPoint) -> CGFloat {
            guard let container = transitionContainer else { return 0 }
            if isMatched {
                let maxAxis = max(container.bounds.width, container.bounds.height)
                let progress = (offset.x / maxAxis + offset.y / maxAxis) * 1.0
                return isPresenting ? -progress : progress
            } else {
                let progress = isTransitioningVertically ? offset.y / container.bounds.height : offset.x / container.bounds.width
                return isPresenting ? -progress : progress
            }
        }
        switch gr.state {
        case .began:
            options.onDragStart?(self)
            if !isTransitioning {
                beginInteractiveTransition()
                view.dismiss()
            } else {
                beginInteractiveTransition()
                pause(view: foregroundContainerView, animationForKey: "position")
            }
            totalTranslation = .zero
        case .changed:
            let translation = gr.translation(in: nil)
            gr.setTranslation(.zero, in: nil)
            totalTranslation += translation
            let progress = progressFrom(offset: translation)
            if isMatched {
                foregroundContainerView.center = foregroundContainerView.center + translation * options.dragTranslationFactor
            }
            fractionCompleted = (fractionCompleted + progress).clamp(0, 1)
        default:
            let translationPlusVelocity = totalTranslation + gr.velocity(in: nil)
            let shouldDismiss = translationPlusVelocity.x + translationPlusVelocity.y > 80
            let shouldFinish = isPresenting ? !shouldDismiss : shouldDismiss
            if shouldDismiss {
                foregroundContainerView.isUserInteractionEnabled = false
                backgroundView?.overlayView?.isUserInteractionEnabled = false
            }
            endInteractiveTransition(shouldFinish: shouldFinish)
        }
    }
}

extension MatchTransition: UIGestureRecognizerDelegate {
    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer.view?.canBeDismissed == true else { return false }
        let velocity = dismissGestureRecognizer.velocity(in: nil)
        let horizontal = options.canDismissHorizontally && velocity.x > abs(velocity.y)
        let vertical = options.canDismissVertically && velocity.y > abs(velocity.x)
        isTransitioningVertically = vertical
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


private class MatchTransitionContainerView: UIView {
    let contentView = UIView()

    override var cornerRadius: CGFloat {
        didSet {
            contentView.cornerRadius = cornerRadius
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(contentView)
        cornerCurve = .continuous
        contentView.cornerCurve = .continuous
        contentView.autoresizingMask = []
        contentView.autoresizesSubviews = false
        contentView.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
    }

    func recalculateShadowPath() {
        shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
    }
}
