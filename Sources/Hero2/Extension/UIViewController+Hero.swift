//
//  File.swift
//
//
//  Created by Luke Zhao on 10/28/21.
//

import UIKit

extension UIView {
    fileprivate func findViewMatchType<T>(_ type: T.Type) -> T? {
        if let view = self as? T {
            return view
        } else {
            for child in subviews.reversed() {
                if let match = child.findViewMatchType(type) {
                    return match
                }
            }
        }
        return nil
    }
}

extension UIViewController {
    func findObjectMatchType<T>(_ type: T.Type) -> T? {
        if let match = findViewControllerMatchType(type) {
            return match
        }
        if let match = view.findViewMatchType(type) {
            return match
        }
        return nil
    }

    fileprivate func findViewControllerMatchType<T>(_ type: T.Type) -> T? {
        if let viewController = self as? T {
            return viewController
        } else {
            for child in children.reversed() {
                if let match = child.findViewControllerMatchType(type) {
                    return match
                }
            }
        }
        return nil
    }
}
