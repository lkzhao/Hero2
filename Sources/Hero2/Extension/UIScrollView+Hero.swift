//
//  File.swift
//
//
//  Created by Luke Zhao on 10/24/21.
//

import UIKit

extension UIScrollView {
    fileprivate struct AssociatedKeys {
        static var disableTopBounce = "disableTopBounce"
    }

    public var disableTopBounce: Bool {
        get { objc_getAssociatedObject(self, &type(of: self).AssociatedKeys.disableTopBounce) as? Bool ?? false }
        set {
            objc_setAssociatedObject(self, &type(of: self).AssociatedKeys.disableTopBounce, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue {
                _ = UIScrollView.swizzleSetContentOffset
                if contentOffset.y < -adjustedContentInset.top {
                    contentOffset.y = -adjustedContentInset.top
                }
            }
        }
    }
    static let swizzleSetContentOffset: Void = {
        guard let originalMethod = class_getInstanceMethod(UIScrollView.self, NSSelectorFromString("setContentOffset:")),
            let swizzledMethod = class_getInstanceMethod(UIScrollView.self, #selector(swizzled_setContentOffset))
        else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()

    @objc func swizzled_setContentOffset(_ contentOffset: CGPoint) {
        if disableTopBounce {
            swizzled_setContentOffset(CGPoint(x: contentOffset.x, y: max(-adjustedContentInset.top, contentOffset.y)))
        } else {
            swizzled_setContentOffset(contentOffset)
        }
    }
}
