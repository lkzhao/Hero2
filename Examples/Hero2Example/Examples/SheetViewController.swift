//
//  SheetViewController.swift
//  Hero2Example
//
//  Created by Luke Zhao on 10/24/21.
//  Copyright © 2021 Luke Zhao. All rights reserved.
//

import Hero2
import UIComponent
import UIKit

class SheetViewController: ComponentViewController {
  override var component: Component {
    ConstraintReader {
      Text("\($0.maxSize)").tappableView {
        $0.present(SheetViewController())
      }.centered()
    }
  }

  init() {
    super.init(nibName: nil, bundle: nil)
    transition = SheetTransition()
    modalPresentationStyle = .custom
//    transitioningDelegate = nil
//    modalPresentationStyle = .automatic
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}