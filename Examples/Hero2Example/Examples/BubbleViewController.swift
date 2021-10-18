//
//  BubbleTransition.swift
//  Hero2Example
//
//  Created by Luke Zhao on 10/17/21.
//  Copyright © 2021 Luke Zhao. All rights reserved.
//

import Hero2
import UIComponent
import UIKit

class BubbleViewController: ComponentViewController {
  override var component: Component {
    VStack {
      Spacer()
      HStack(justifyContent: .spaceEvenly) {
        Image(systemName: "plus").id("plus").tintColor(.white).heroModifiers([.fade]).centered().tappableView {
          let vc = BubbleMaskDetailViewController()
          $0.parentViewController?.navigationController?.pushViewController(vc, animated: true)
        }.size(width: 64, height: 64).cornerRadius(32).backgroundColor(.systemBlue).heroID("bubble-mask")
        Image(systemName: "plus").id("plus").tintColor(.white).heroModifiers([.fade]).centered().tappableView {
          let vc = BubbleScaleDetailViewController()
          $0.parentViewController?.navigationController?.pushViewController(vc, animated: true)
        }.size(width: 64, height: 64).cornerRadius(32).backgroundColor(.systemRed).heroID("bubble-scale")
      }
    }.inset(10)
  }
}

class BubbleMaskDetailViewController: ComponentViewController {
  override var component: Component {
    VStack(spacing: 20, alignItems: .center) {
      Text("Bubble Transition", font: .boldSystemFont(ofSize: 26))
      Text("Content is masked", font: .systemFont(ofSize: 22))
    }.fill().inset(20)
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBlue
    view.heroID = "bubble-mask"
    view.clipsToBounds = true
    view.cornerRadius = 38
    view.heroModifiers = [.fade]
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    componentView.heroModifiers = [.forceTransition] // this forces componentView to participate in the transition, causing it to be independent and stay in place
  }
  @objc func didTap() {
    navigationController?.popViewController(animated: true)
  }
}

class BubbleScaleDetailViewController: ComponentViewController {
  override var component: Component {
    VStack(spacing: 20, alignItems: .center) {
      Text("Bubble Transition", font: .boldSystemFont(ofSize: 26))
      Text("Content is scaled", font: .systemFont(ofSize: 22))
    }.fill().inset(20)
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemRed
    view.heroID = "bubble-scale"
    view.clipsToBounds = true
    view.cornerRadius = 38
    view.heroModifiers = [.fade, .scaleSize]
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
  }
  @objc func didTap() {
    navigationController?.popViewController(animated: true)
  }
}
