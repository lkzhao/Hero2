//
//  DelayViewController.swift
//  Hero2Example
//
//  Created by Luke Zhao on 7/28/21.
//  Copyright © 2021 Luke Zhao. All rights reserved.
//

import Hero2
import UIComponent
import UIKit

class MyTestImageView: UIImageView {
  override var alpha: CGFloat {
    didSet {
      print("set alpha to \(alpha)")
    }
  }
}
class DelayViewController: ComponentViewController {
  let imageView = MyTestImageView(image: UIImage(systemName: "rectangle"))
  override func viewDidLoad() {
    super.viewDidLoad()
    imageView.heroModifiers = [.scale(0.2), .fade, .delay(0.3)]
  }
  override var component: Component {
    VStack(spacing: 8) {
      imageView
      Image(systemName: "chevron.right").tintColor(.systemBlue).tappableView {
        $0.present(DelayDetailViewController())
      }
    }.inset(20)
  }
}

class DelayDetailViewController: ComponentViewController {
  override var component: Component {
    VStack(spacing: 8) {
      Space(height: 100)
      Image(systemName: "chevron.left").tintColor(.systemBlue).tappableView {
        $0.dismiss()
      }
    }.inset(20)
  }
}
