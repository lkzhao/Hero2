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
        ExampleItem(name: "Sheet", shouldPresent: true, viewController: SheetViewController())
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
  let shouldPresent: Bool
  let viewController: () -> UIViewController
  init(name: String, shouldPresent: Bool = false, viewController: @autoclosure @escaping () -> UIViewController) {
    self.name = name
    self.shouldPresent = shouldPresent
    self.viewController = viewController
  }
  func build() -> Component {
    VStack {
      Text(name)
    }.inset(20).tappableView {
      let vc = viewController()
      if shouldPresent {
        $0.present(vc)
      } else {
        $0.push(vc)
      }
    }
  }
}
