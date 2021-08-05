// UIView+Extensions.swift
// Copyright © 2020 Noto. All rights reserved.

import UIKit

extension UIView {
  var parentViewController: UIViewController? {
    var responder: UIResponder? = self
    while responder is UIView {
      responder = responder!.next
    }
    return responder as? UIViewController
  }
  
  func present(_ viewController: UIViewController, completion: (() -> Void)? = nil) {
    parentViewController?.present(viewController, animated: true, completion: completion)
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
}

extension UIView {
  private struct AssociateKey {
    static var borderColor: Void?
    static var shadowColor: Void?
    static var hitTestSlop: Void?
  }
  
  @objc var cornerRadius: CGFloat {
    get { return layer.cornerRadius }
    set { layer.cornerRadius = newValue }
  }
  
  @objc var zPosition: CGFloat {
    get { layer.zPosition }
    set { layer.zPosition = newValue }
  }

  @objc var borderWidth: CGFloat {
    get { layer.borderWidth }
    set { layer.borderWidth = newValue }
  }
  
  @objc var shadowOpacity: CGFloat {
    get { CGFloat(layer.shadowOpacity) }
    set { layer.shadowOpacity = Float(newValue) }
  }
  
  @objc var shadowRadius: CGFloat {
    get { layer.shadowRadius }
    set { layer.shadowRadius = newValue }
  }
  
  @objc var shadowOffset: CGSize {
    get { layer.shadowOffset }
    set { layer.shadowOffset = newValue }
  }
  
  @objc var shadowPath: UIBezierPath? {
    get { layer.shadowPath.map { UIBezierPath(cgPath: $0) } }
    set { layer.shadowPath = newValue?.cgPath }
  }
  
  private static let swizzleTraitCollection: Void = {
     guard let originalMethod = class_getInstanceMethod(UIView.self, #selector(traitCollectionDidChange(_:))),
           let swizzledMethod = class_getInstanceMethod(UIView.self, #selector(swizzled_traitCollectionDidChange(_:)))
     else { return }
     method_exchangeImplementations(originalMethod, swizzledMethod)
  }()
  
  var borderColor: UIColor? {
    get {
      return objc_getAssociatedObject(self, &AssociateKey.borderColor) as? UIColor
    }
    set {
      _ = UIView.swizzleTraitCollection
      objc_setAssociatedObject(self, &AssociateKey.borderColor, newValue, .OBJC_ASSOCIATION_RETAIN)
      layer.borderColor = borderColor?.resolvedColor(with: traitCollection).cgColor
    }
  }

  var shadowColor: UIColor? {
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
