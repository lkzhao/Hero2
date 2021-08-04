//
//  InstagramViewController.swift
//  Hero2Example
//
//  Created by Luke Zhao on 8/2/21.
//  Copyright © 2021 Luke Zhao. All rights reserved.
//

import UIKit
import UIComponent
import Hero2
import Kingfisher

class InstagramViewController: ComponentViewController {
  let images = ImageData.testImages

  override var component: Component {
    Waterfall(columns: 3, spacing: 1) {
      for image in images {
        AsyncImage(image.url)
          .contentMode(.scaleAspectFill)
          .clipsToBounds(true)
          .size(width: .fill, height: .aspectPercentage(1))
          .heroID(image.id)
          .heroModifiers([.whenMatched([.snapshotType(.none)])])
          .tappableView { [unowned self] in
            self.didTap(image: image)
          }
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.heroModifiers = [.overlayColor(.black.withAlphaComponent(0.5))]
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if let image = toBePresentedImage {
      toBePresentedImage = nil
      present(image: image)
    }
  }
  
  var toBePresentedImage: ImageData?
  func didTap(image: ImageData) {
    if presentingViewController != nil {
      toBePresentedImage = image
    } else {
      present(image: image)
    }
  }
  
  func present(image: ImageData) {
    let detailVC = InstagramDetailViewController()
    detailVC.image = image
    present(detailVC, animated: true, completion: nil)
  }
}

class InstagramDetailViewController: ComponentViewController {
  var image: ImageData! {
    didSet {
      imageView.kf.setImage(with: image.url)
      imageView.heroID = image.id
    }
  }
  let imageView = UIImageView()
  lazy var panGR = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gr:)))

  override var component: Component {
    VStack {
      HStack(alignItems: .center) {
        Image(systemName: "chevron.left").tintColor(.label)
      }.size(width: .fill, height: 44).overlay(HStack(justifyContent: .center, alignItems: .center) {
        Text("Explore", font: .boldSystemFont(ofSize: 16))
      }.size(width: .fill, height: .fill)).inset(8)
      Separator()
      HStack(spacing: 8, alignItems: .center) {
        Space(size: CGSize(width: 40, height: 40)).view().backgroundColor(.systemGray).cornerRadius(20)
        Text("Hero Transition")
        Text("Follow").textColor(.systemBlue)
      }.inset(8)
      imageView.size(width: .fill, height: .aspectPercentage(image.size.height / image.size.width))
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    transition.isUserInteractionEnabled = true
    transition.duration = 5
    imageView.heroModifiers = [.snapshotType(.none)]
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    componentView.cornerRadius = 40
    componentView.clipsToBounds = true
    view.backgroundColor = nil
    view.heroModifiers = [.snapshotType(.none)]
    componentView.backgroundColor = .systemBackground
    panGR.delegate = self
    view.addGestureRecognizer(panGR)
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if !componentView.hasReloaded {
      componentView.reloadData()
    }
    componentView.heroModifiers = [.match(image.id)]
  }
  
  @objc func didTap() {
    dismiss(animated: true, completion: nil)
  }

  var initialFractionCompleted: CGFloat = 0
  var initialPosition: CGPoint = .zero
  @objc func handlePan(gr: UIPanGestureRecognizer) {
    func progressFrom(offset: CGPoint) -> CGFloat {
      let progress = (offset.x + offset.y) / ((view.bounds.height + view.bounds.width) / 4)
      return (transition.isPresenting != transition.isReversed ? -progress : progress)
    }
    switch gr.state {
    case .began:
      transition.beginInteractiveTransition()
      if !isBeingPresented, !isBeingDismissed {
        dismiss(animated: true, completion: nil)
      }
      initialFractionCompleted = transition.fractionCompleted
      initialPosition = transition.position(for: componentView) ?? view.bounds.center
    case .changed:
      guard transition.isTransitioning else { return }
      let translation = gr.translation(in: view)
      let progress = progressFrom(offset: translation)
      transition.apply(position: initialPosition + translation, to: componentView)
      transition.fractionCompleted = (initialFractionCompleted + progress).clamp(0, 1)
    default:
      guard transition.isTransitioning else { return }
      let combinedOffset = gr.translation(in: view) + gr.velocity(in: view)
      let progress = progressFrom(offset: combinedOffset)
      let shouldFinish = progress > 0.5
      transition.endInteractiveTransition(shouldFinish: shouldFinish)
      if isBeingPresented != shouldFinish {
        // dismissing, do not let our view handle touches anymore.
        // this allows user to swipe on the background view immediately
        view.isUserInteractionEnabled = false
      }
    }
  }
}

extension InstagramDetailViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    let velocity = panGR.velocity(in: nil)
    // only allow right and down swipe
    return velocity.x > abs(velocity.y) || velocity.y > abs(velocity.x)
  }
}

