// The MIT License (MIT)
//
// Copyright (c) 2016 Luke Zhao <me@lkzhao.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

public extension UIView {
  fileprivate struct AssociatedKeys {
    static var heroID    = "heroID"
    static var heroModifiers = "heroModifers"
  }
  
  @IBInspectable var heroID: String? {
    get { return objc_getAssociatedObject(self, &type(of: self).AssociatedKeys.heroID) as? String }
    set { objc_setAssociatedObject(self, &type(of: self).AssociatedKeys.heroID, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  var heroModifiers: [HeroModifier]? {
    get { return objc_getAssociatedObject(self, &type(of: self).AssociatedKeys.heroModifiers) as? [HeroModifier] }
    set { objc_setAssociatedObject(self, &type(of: self).AssociatedKeys.heroModifiers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }
}

extension UIView {
  var flattendSubviews: [UIView] {
    return [self] + subviews.flatMap { $0.flattendSubviews }
  }
}
