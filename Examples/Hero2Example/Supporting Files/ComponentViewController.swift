//
//  ComponentViewController.swift
//  UIComponentExample
//
//  Created by Luke Zhao on 6/14/21.
//  Copyright © 2021 Luke Zhao. All rights reserved.
//

import Hero2
import UIComponent
import UIKit

class ComponentViewController: UIViewController {
  let componentView = ComponentScrollView()
  var transition: Transition = HeroTransition() {
    didSet {
      transitioningDelegate = transition
    }
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    modalPresentationStyle = .fullScreen
    transitioningDelegate = transition
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    componentView.contentInsetAdjustmentBehavior = .always
    view.backgroundColor = .systemBackground
    view.addSubview(componentView)
    reloadComponent()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard !transition.isTransitioning else { return } // disable child layout during transition since that might mess up the
    componentView.frame = view.bounds
  }

  func reloadComponent() {
    componentView.component = component
  }

  var component: Component {
    VStack(justifyContent: .center, alignItems: .center) {
      Text("Empty")
    }.size(width: .fill)
  }
}

extension ComponentViewController: TransitionProvider {
  func transitionFor(presenting: Bool, otherViewController: UIViewController) -> Transition? {
    transition
  }
}
