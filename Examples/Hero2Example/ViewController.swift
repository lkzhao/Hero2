//
//  ViewController.swift
//  Hero2Example
//
//  Created by Luke Zhao on 2018-12-13.
//  Copyright © 2018 Luke Zhao. All rights reserved.
//

import Hero2
import UIKit
import UIComponent

class ViewController: ComponentViewController {
  override var component: Component {
    VStack {
      Join {
        ExampleItem(name: "Match", viewController: MatchViewController())
      } separator: {
        Separator()
      }
    }
  }
}

struct ExampleItem: ComponentBuilder {
  let name: String
  let viewController: () -> UIViewController
  init(name: String, viewController: @autoclosure @escaping () -> UIViewController) {
    self.name = name
    self.viewController = viewController
  }
  func build() -> Component {
    VStack {
      Text(name)
    }.inset(20).tappableView {
      $0.present(viewController())
    }
  }
}
