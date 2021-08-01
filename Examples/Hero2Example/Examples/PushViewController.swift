//
//  PushViewController.swift
//  Hero2Example
//
//  Created by Luke Zhao on 7/29/21.
//  Copyright © 2021 Luke Zhao. All rights reserved.
//

import UIKit
import UIComponent
import Hero2

class PushViewController: ComponentViewController {
  override var component: Component {
    VStack(spacing: 8, justifyContent: .center, alignItems: .center) {
      Text("Present Detail VC").textColor(.systemBlue).tappableView {
        $0.present(PushDetailViewController())
      }
    }.size(width: .fill).inset(20)
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.heroModifiers = [.overlayColor(UIColor.black.withAlphaComponent(0.2)), .snapshotType(.none)]
  }
}


class PushDetailViewController: ComponentViewController {
  override var component: Component {
    VStack(spacing: 8) {
      Image(systemName: "chevron.left").tintColor(.systemBlue).tappableView {
        $0.dismiss()
      }
      Text("PushDetailViewController")
    }.inset(20)
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.shadowRadius = 20
    view.shadowOffset = .zero
    view.backgroundColor = .systemGroupedBackground
    view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(gr:))))
  }
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    view.heroModifiers = [.translate(CGPoint(x: view.bounds.width, y: 0)), .beginWith([.shadowOpacity(0.5)]), .snapshotType(.none)]
  }
  @objc func handlePan(gr: UIPanGestureRecognizer) {
    switch gr.state {
    case .began:
      transition.beginInteractiveTransition()
      dismiss(animated: true, completion: nil)
    case .changed:
      let trans = gr.translation(in: view)
      transition.fractionCompleted = trans.x / view.bounds.width
//      transition.pause(view: view, animationForKey: "transform")
//      view.transform = .identity.translatedBy(x: trans.x, y: trans.y)
    default:
      transition.endInteractiveTransition(shouldFinish: gr.translation(in: view).x + gr.velocity(in: view).x > view.bounds.width / 4)
    }
  }
}
