//
//  File.swift
//
//
//  Created by Luke Zhao on 10/24/21.
//

import UIKit
import BaseToolbox
import ScreenCorners

public protocol SheetBackgroundDelegate {
  func sheetTopInsetFor(sheetTransition: SheetTransition) -> CGFloat
  func sheetApplyOverlay(sheetTransition: SheetTransition) -> Bool
}

public protocol SheetForegroundDelegate {
  func canInteractivelyDismiss(sheetTransition: SheetTransition) -> Bool
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
  var transition: SheetTransition!
  weak var originalSuperview: UIView?
  override func presentationTransitionWillBegin() {
    super.presentationTransitionWillBegin()
    guard let containerView = containerView else { return }
    originalSuperview = presentingViewController.view.superview

    overlayView.backgroundColor = UIColor {
      if $0.userInterfaceStyle == .dark {
        return UIColor(white: $0.userInterfaceLevel == .elevated ? 0.0 : 0.4, alpha: 0.2)
      } else {
        return UIColor(white: 0.3, alpha: 0.2)
      }
    }
    overlayView.zPosition = 100

    if presentingViewController.findObjectMatchType(SheetBackgroundDelegate.self)?.sheetApplyOverlay(sheetTransition: transition) != false {
      presentingViewController.view.addSubview(overlayView)
    }

    containerView.isUserInteractionEnabled = false
    containerView.addSubview(presentingViewController.view)
    containerView.addSubview(presentedViewController.view)
    presentedViewController.view.frame = containerView.bounds
    presentedViewController.view.setNeedsLayout()
    presentedViewController.view.layoutIfNeeded()
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
    guard let containerView = containerView else { return }
    containerView.isUserInteractionEnabled = false
  }
  override func dismissalTransitionDidEnd(_ completed: Bool) {
    containerView?.isUserInteractionEnabled = true
    super.dismissalTransitionDidEnd(completed)
    if completed {
      overlayView.removeFromSuperview()
      if let originalSuperview = originalSuperview {
        originalSuperview.addSubview(presentingViewController.view)
      }
    }
  }
  var isIpadHorizontal: Bool {
    guard let container = containerView else { return false }
    return container.bounds.width >= 1024 && container.traitCollection.verticalSizeClass == .regular
  }
  var isCompactVertical: Bool {
    guard let container = containerView else { return false }
    return container.traitCollection.verticalSizeClass == .compact
  }
  var backTransform: CGAffineTransform {
    guard let container = containerView, let back = presentingViewController.view else { return .identity }
    let sideInset: CGFloat = isIpadHorizontal ? 20 : 16
    let scaleSideFactor: CGFloat = sideInset / container.bounds.width
    let scale: CGFloat = 1 - scaleSideFactor * 2
    let topInset = presentingViewController.findObjectMatchType(SheetBackgroundDelegate.self)?.sheetTopInsetFor(sheetTransition: transition) ?? 0
    if isCompactVertical {
      return .identity
    } else if hasParentSheet {
      return .identity.translatedBy(y: -back.bounds.height * scaleSideFactor - 10).scaledBy(scale)
    } else if isIpadHorizontal {
      return .identity
    } else {
      return .identity.translatedBy(y: -container.bounds.height * scaleSideFactor + container.safeAreaInsets.top - topInset).scaledBy(scale)
    }
  }
  var thirdTransform: CGAffineTransform {
    if (isIpadHorizontal && !hasParentSheet) || isCompactVertical {
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
    back.cornerRadius = transition.cornerRadius
    overlayView.alpha = 1
  }

  func applyDismissedState() {
    guard let container = containerView, let front = presentedViewController.view, let back = presentingViewController.view else { return }
    front.transform = .identity.translatedBy(y: container.bounds.height)
    back.transform = .identity
    if let parentSheetPresentationController = parentSheetPresentationController {
      parentSheetPresentationController.presentingViewController.view.transform = parentSheetPresentationController.backTransform
    }
    back.layer.cornerCurve = .continuous
    if hasParentSheet {
      back.cornerRadius = transition.cornerRadius
    } else {
      back.cornerRadius = UIScreen.main.displayCornerRadius
    }
    overlayView.alpha = 0
  }
  override func containerViewDidLayoutSubviews() {
    super.containerViewDidLayoutSubviews()
    guard let container = containerView else { return }
    let sheetFrame: CGRect
    if isIpadHorizontal {
      // following default iOS iPad Sheet size
      let sheetSize = CGSize(width: 704, height: container.bounds.inset(by: container.safeAreaInsets).height - 44)
      sheetFrame = CGRect(center: container.bounds.center, size: sheetSize)
    } else if isCompactVertical {
      sheetFrame = container.bounds
    } else {
      let topInset = container.safeAreaInsets.top + 10
      sheetFrame = CGRect(x: 0, y: topInset, width: container.bounds.width, height: container.bounds.height - topInset)
    }
    if hasParentSheet {
      presentingViewController.view.frameWithoutTransform = sheetFrame
    } else {
      presentingViewController.view.frameWithoutTransform = container.bounds
    }

    overlayView.frameWithoutTransform = presentingViewController.view.bounds
    
    presentedViewController.view.frameWithoutTransform = sheetFrame
    presentedViewController.view.cornerRadius = isCompactVertical ? UIScreen.main.displayCornerRadius : transition.cornerRadius
    presentedViewController.view.layer.maskedCorners = isIpadHorizontal ? [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner] : [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    presentedViewController.view.clipsToBounds = true
    if !transition.isAnimating, !hasChildSheet {
      applyPresentedState()
    }
  }
  var childScrollView: UIScrollView? {
    guard let vc = (presentedViewController as? UINavigationController)?.topViewController else { return nil }
    return vc.view.flattendSubviews.first { view in
      (view is UIScrollView) && view.bounds.width == vc.view.bounds.width
    } as? UIScrollView
  }
  var startLocation: CGFloat = 0
  var lastDraggedScrollView: UIScrollView?
  var initialFractionCompleted: CGFloat = 0
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
        progress = (initialFractionCompleted + progress).clamp(0, 1)
        transition.fractionCompleted = progress
      }
    default:
      lastDraggedScrollView?.disableTopBounce = false
      if transition.isInteractive {
        let translation = location - startLocation
        var progress = (v.y + translation) / presentedViewController.view.frameWithoutTransform.height
        progress = transition.isPresenting != transition.isReversed ? -progress : progress
        progress = (initialFractionCompleted + progress).clamp(0, 1)
        transition.endInteractiveTransition(shouldFinish: progress > 0.5)
      }
    }
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    presentedViewController.findObjectMatchType(SheetForegroundDelegate.self)?.canInteractivelyDismiss(sheetTransition: transition) ?? true
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
      if let otherPanGR = otherGestureRecognizer as? UIPanGestureRecognizer {
          return otherPanGR.minimumNumberOfTouches <= 1
      } else {
          return false
      }
  }
}

public class SheetTransition: Transition {
  weak var presentationController: SheetPresentationController!
  public var cornerRadius: CGFloat = 10

  public override var automaticallyLayoutToView: Bool {
    false
  }

  public override func animate() {
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

  public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
    let presentationController = SheetPresentationController(presentedViewController: presented, presenting: presenting)
    presentationController.transition = self
    self.presentationController = presentationController
    return presentationController
  }
}
