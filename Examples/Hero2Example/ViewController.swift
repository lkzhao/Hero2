//
//  ViewController.swift
//  Hero2Example
//
//  Created by Luke Zhao on 2018-12-13.
//  Copyright © 2018 Luke Zhao. All rights reserved.
//

import Hero2
import UIComponent
import UIKit

class ViewController: ComponentViewController {
  override var component: Component {
    VStack {
      Join {
        ExampleItem(name: "Match", viewController: MatchViewController())
        ExampleItem(name: "Bubble", viewController: BubbleViewController())
        ExampleItem(name: "Push", viewController: PushViewController())
        ExampleItem(name: "ImageGallery", viewController: ImageGalleryViewController())
        ExampleItem(name: "Instagram", viewController: InstagramViewController())
      } separator: {
        Separator()
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Hero2 Examples"
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
      $0.push(viewController())
    }
  }
}
