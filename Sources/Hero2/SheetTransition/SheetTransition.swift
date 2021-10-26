//
//  File.swift
//
//
//  Created by Luke Zhao on 10/24/21.
//

import UIKit
import BaseToolbox

let sheetCornerRadius: CGFloat = 12

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

    presentingViewController.view.addSubview(overlayView)

    presentedViewController.view.cornerRadius = sheetCornerRadius
    presentedViewController.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    presentedViewController.view.clipsToBounds = true

    containerView.isUserInteractionEnabled = false
    containerView.addSubview(presentingViewController.view)
    containerView.addSubview(presentedViewController.view)
    containerView.layoutIfNeeded()
  }
  override func presentationTransitionDidEnd(_ completed: Bool) {
    containerView?.isUserInteractionEnabled = true
    super.presentationTransitionDidEnd(completed)
    if completed {
      panGR.delegate = self
      presentedViewController.view.addGestureRecognizer(panGR)
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
  var backTransform: CGAffineTransform {
    guard let container = containerView, let back = presentingViewController.view else { return .identity }
    if hasParentSheet {
      return .identity.translatedBy(y: -back.bounds.height * 0.1 / 2 - 10).scaledBy(0.9)
    } else {
      return .identity.translatedBy(y: -container.bounds.height * 0.1 / 2 + container.safeAreaInsets.top).scaledBy(0.9)
    }
  }

  func applyPresentedState() {
    guard let front = presentedViewController.view, let back = presentingViewController.view else { return }
    front.transform = .identity
    if let parentSheetPresentationController = parentSheetPresentationController {
      parentSheetPresentationController.presentingViewController.view.transform = parentSheetPresentationController.backTransform.scaledBy(0.985)
    }
    back.transform = backTransform
    back.cornerRadius = sheetCornerRadius
    overlayView.alpha = 1
  }

  func applyDismissedState() {
    guard let container = containerView, let front = presentedViewController.view, let back = presentingViewController.view else { return }
    front.transform = .identity.translatedBy(y: container.bounds.height)
    back.transform = .identity
    if let parentSheetPresentationController = parentSheetPresentationController {
      parentSheetPresentationController.presentingViewController.view.transform = parentSheetPresentationController.backTransform
    }
    if hasParentSheet {
      back.cornerRadius = sheetCornerRadius
    } else {
      back.cornerRadius = 39
    }
    overlayView.alpha = 0
  }
  override func containerViewDidLayoutSubviews() {
    super.containerViewDidLayoutSubviews()
    guard let container = containerView else { return }
    let topInset = container.safeAreaInsets.top + 10
    let sheetFrame = CGRect(x: 0, y: topInset, width: container.bounds.width, height: container.bounds.height - topInset)
    if hasParentSheet {
      presentingViewController.view.frameWithoutTransform = sheetFrame
    } else {
      presentingViewController.view.frameWithoutTransform = container.bounds
    }
    presentedViewController.view.frameWithoutTransform = sheetFrame
    overlayView.frameWithoutTransform = presentingViewController.view.bounds
    if !transition.isTransitioning, !hasChildSheet {
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
        transition.beginInteractiveTransition()
        presentedViewController.dismiss(animated: true, completion: nil)
      }
      if transition.isInteractive {
        let translation = location - startLocation
        let progress = translation / presentedViewController.view.frameWithoutTransform.height
        transition.fractionCompleted = progress
      }
    default:
      lastDraggedScrollView?.disableTopBounce = false
      if transition.isTransitioning {
        let shouldFinish = (v.y + location) / presentedViewController.view.frameWithoutTransform.height > 0.5
        transition.endInteractiveTransition(shouldFinish: shouldFinish)
      }
    }
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}

public class SheetTransition: Transition {
  var presentationController: SheetPresentationController!
  public override func animate() -> (dismissed: () -> (), presented: () -> (), completed: (Bool) -> ()) {
    guard let presentationController = presentationController else {
      fatalError()
    }
    let dismissed = {
      presentationController.applyDismissedState()
    }
    let presented = {
      presentationController.applyPresentedState()
    }
    let completed = { (finished: Bool) in }
    return (dismissed, presented, completed)
  }

  public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
    presentationController = SheetPresentationController(presentedViewController: presented, presenting: presenting)
    presentationController.transition = self
    return presentationController
  }
}
