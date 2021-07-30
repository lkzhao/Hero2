// UIView+Extensions.swift
// Copyright © 2020 Noto. All rights reserved.

import SafariServices
import UIKit

extension UIView {
  private struct AssociateKey {
    static var borderColor: Void?
    static var shadowColor: Void?
    static var hitTestSlop: Void?
  }
  
  @objc open var cornerRadius: CGFloat {
    get { return layer.cornerRadius }
    set { layer.cornerRadius = newValue }
  }
  
  @objc open var zPosition: CGFloat {
    get { layer.zPosition }
    set { layer.zPosition = newValue }
  }

  @objc open var borderWidth: CGFloat {
    get { layer.borderWidth }
    set { layer.borderWidth = newValue }
  }
  
  @objc open var shadowOpacity: CGFloat {
    get { CGFloat(layer.shadowOpacity) }
    set { layer.shadowOpacity = Float(newValue) }
  }
  
  @objc open var shadowRadius: CGFloat {
    get { layer.shadowRadius }
    set { layer.shadowRadius = newValue }
  }
  
  @objc open var shadowOffset: CGSize {
    get { layer.shadowOffset }
    set { layer.shadowOffset = newValue }
  }
  
  @objc open var shadowPath: UIBezierPath? {
    get { layer.shadowPath.map { UIBezierPath(cgPath: $0) } }
    set { layer.shadowPath = newValue?.cgPath }
  }
  
  private static let swizzleTraitCollection: Void = {
     guard let originalMethod = class_getInstanceMethod(UIView.self, #selector(traitCollectionDidChange(_:))),
           let swizzledMethod = class_getInstanceMethod(UIView.self, #selector(swizzled_traitCollectionDidChange(_:)))
     else { return }
     method_exchangeImplementations(originalMethod, swizzledMethod)
  }()
  
  open var borderColor: UIColor? {
    get {
      return objc_getAssociatedObject(self, &AssociateKey.borderColor) as? UIColor
    }
    set {
      _ = UIView.swizzleTraitCollection
      objc_setAssociatedObject(self, &AssociateKey.borderColor, newValue, .OBJC_ASSOCIATION_RETAIN)
      layer.borderColor = borderColor?.resolvedColor(with: traitCollection).cgColor
    }
  }

  open var shadowColor: UIColor? {
    get {
      return objc_getAssociatedObject(self, &AssociateKey.shadowColor) as? UIColor
    }
    set {
      _ = UIView.swizzleTraitCollection
      objc_setAssociatedObject(self, &AssociateKey.shadowColor, newValue, .OBJC_ASSOCIATION_RETAIN)
      layer.shadowColor = shadowColor?.resolvedColor(with: traitCollection).cgColor
    }
  }
  
  @objc func swizzled_traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    swizzled_traitCollectionDidChange(previousTraitCollection)
    if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
      if let borderColor = borderColor {
        layer.borderColor = borderColor.resolvedColor(with: traitCollection).cgColor
      }
      if let shadowColor = shadowColor {
        layer.shadowColor = shadowColor.resolvedColor(with: traitCollection).cgColor
      }
    }
  }
}

public extension UIView {
  class var isInAnimationBlock: Bool {
    UIView.perform(NSSelectorFromString("_isInAnimationBlock")) != nil
  }

  var parentViewController: UIViewController? {
    var responder: UIResponder? = self
    while responder is UIView {
      responder = responder!.next
    }
    return responder as? UIViewController
  }
  
  var presentedViewController: UIViewController? {
    return parentViewController?.presentedViewController
  }

  var presentingViewController: UIViewController? {
    return parentViewController?.presentingViewController
  }
  
  var frameWithoutTransform: CGRect {
    get {
      CGRect(center: center, size: bounds.size)
    }
    set {
      bounds.size = newValue.size
      center = newValue.offsetBy(
        dx: bounds.width * (layer.anchorPoint.x - 0.5),
        dy: bounds.height * (layer.anchorPoint.y - 0.5)
      ).center
    }
  }

  var flattendSubviews: [UIView] {
    return [self] + subviews.flatMap { $0.flattendSubviews }
  }

  func superview<T: UIView>(matchingType _: T.Type) -> T? {
    var current: UIView? = self
    while let next = current?.superview {
      if let next = next as? T {
        return next
      }
      current = next
    }
    return nil
  }

  func findSubview<ViewType: UIView>(checker: ((ViewType) -> Bool)? = nil) -> ViewType? {
    for subview in [self] + flattendSubviews.reversed() {
      if let subview = subview as? ViewType, checker?(subview) != false {
        return subview
      }
    }
    return nil
  }
  
  func contains(view: UIView) -> Bool {
    if view == self {
      return true
    }
    return subviews.contains(where: { $0.contains(view: view) })
  }

  func closestViewMatchingType<ViewType: UIView>(_: ViewType.Type) -> ViewType? {
    return closestViewPassingTest {
      $0 is ViewType
    } as? ViewType
  }

  func closestViewPassingTest(_ test: (UIView) -> Bool) -> UIView? {
    var current: UIView? = self.superview
    while current != nil {
      if test(current!) {
        return current
      }
      current = current?.superview
    }
    return nil
  }
  
  func snapshot(of rect: CGRect? = nil, afterScreenUpdates _: Bool = true) -> UIImage {
    return UIGraphicsImageRenderer(bounds: rect ?? bounds).image { _ in
      drawHierarchy(in: bounds, afterScreenUpdates: true)
    }
  }
}

public extension UIView {
  func present(_ viewController: UIViewController, completion: (() -> Void)? = nil) {
    parentViewController?.present(viewController, animated: true, completion: completion)
  }

  func push(_ viewController: UIViewController) {
    parentViewController?.navigationController?.pushViewController(viewController, animated: true)
  }
  
  func dismiss(completion: (() -> Void)? = nil) {
    guard let viewController = parentViewController else {
      return
    }
    if let navVC = viewController.navigationController, navVC.viewControllers.count > 1 {
      navVC.popViewController(animated: true)
      completion?()
    } else {
      viewController.dismiss(animated: true, completion: completion)
    }
  }

  func dismissModal(completion: (() -> Void)? = nil) {
    guard let viewController = parentViewController else {
      return
    }
    viewController.dismiss(animated: true, completion: completion)
  }
}
