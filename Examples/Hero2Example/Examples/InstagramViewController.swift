//
//  InstagramViewController.swift
//  Hero2Example
//
//  Created by Luke Zhao on 8/2/21.
//  Copyright © 2021 Luke Zhao. All rights reserved.
//

import Hero2
import Kingfisher
import UIComponent
import UIKit
import BaseToolbox

class InstagramViewController: ComponentViewController {
  let images = ImageData.testImages

  override var component: Component {
    Waterfall(columns: 3, spacing: 1) {
      for image in images {
        AsyncImage(image.url)
          .contentMode(.scaleAspectFill)
          .clipsToBounds(true)
          .fill()
          .tappableView { [unowned self] in
            self.didTap(image: image)
          }
          .size(width: .fill, height: .aspectPercentage(1))
          .heroID(image.id)
      }
    }
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

extension InstagramViewController: Matchable {
  func matchedViewFor(transition: MatchModalTransition, otherViewController: UIViewController) -> UIView? {
    guard let otherViewController = otherViewController as? InstagramDetailViewController else { return nil }
    return view.flattendSubviews.first {
      $0.heroID == otherViewController.image.id
    }
  }
}

class InstagramDetailViewController: ComponentViewController {
  var image: ImageData! {
    didSet {
      imageView.kf.setImage(with: image.url)
    }
  }
  let imageView = UIImageView()

  override var component: Component {
    VStack {
      HStack(alignItems: .center) {
        Image(systemName: "chevron.left").tintColor(.label)
      }.size(width: .fill, height: 44).overlay(
        HStack(justifyContent: .center, alignItems: .center) {
          Text("Explore", font: .boldSystemFont(ofSize: 16))
        }.size(width: .fill, height: .fill)
      ).inset(8)
      Separator()
      HStack(spacing: 8, alignItems: .center) {
        Space(size: CGSize(width: 40, height: 40)).view().backgroundColor(.systemGray).cornerRadius(20)
        Text("Hero Transition")
        Text("Follow").textColor(.systemBlue)
      }.inset(8)
      imageView.size(width: .fill, height: .aspectPercentage(image.size.height / image.size.width))
      for i in 0..<100 {
        Text("\(i)").inset(16)
      }
    }
  }

  init() {
    super.init(nibName: nil, bundle: nil)
    transition = MatchModalTransition()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if !componentView.hasReloaded {
      componentView.reloadData()
    }
  }

  @objc func didTap() {
    dismiss(animated: true, completion: nil)
  }
}

extension InstagramDetailViewController: Matchable {
  func matchedViewFor(transition: MatchModalTransition, otherViewController: UIViewController) -> UIView? {
    return imageView
  }
}
