//
//  ImageGalleryViewController.swift
//  Hero2Example
//
//  Created by Luke Zhao on 8/1/21.
//  Copyright © 2021 Luke Zhao. All rights reserved.
//

import UIKit
import UIComponent
import Hero2
import Kingfisher

struct ImageData {
  let id = UUID().uuidString
  let url: URL
  let size: CGSize
}

public struct AsyncImage: ViewComponentBuilder {
  public let url: URL
  
  public init(_ url: URL) {
    self.url = url
  }
  
  public init?(_ urlString: String) {
    guard let url = URL(string: urlString) else { return nil }
    self.url = url
  }
  
  public func build() -> ViewUpdateComponent<SimpleViewComponent<UIImageView>> {
    SimpleViewComponent<UIImageView>().update {
      $0.kf.setImage(with: url)
    }
  }
}

class ImageGalleryViewController: ComponentViewController {
  let images = [
    ImageData(url: URL(string: "https://unsplash.com/photos/Yn0l7uwBrpw/download?force=true&w=640")!,
          size: CGSize(width: 640, height: 360)),
    ImageData(url: URL(string: "https://unsplash.com/photos/J4-xolC4CCU/download?force=true&w=640")!,
          size: CGSize(width: 640, height: 800)),
    ImageData(url: URL(string: "https://unsplash.com/photos/biggKnv1Oag/download?force=true&w=640")!,
          size: CGSize(width: 640, height: 434)),
    ImageData(url: URL(string: "https://unsplash.com/photos/MR2A97jFDAs/download?force=true&w=640")!,
          size: CGSize(width: 640, height: 959)),
    ImageData(url: URL(string: "https://unsplash.com/photos/oaCnDk89aho/download?force=true&w=640")!,
          size: CGSize(width: 640, height: 426)),
    ImageData(url: URL(string: "https://unsplash.com/photos/MOfETox0bkE/download?force=true&w=640")!,
          size: CGSize(width: 640, height: 426)),
    ImageData(url: URL(string: "https://unsplash.com/photos/Yn0l7uwBrpw/download?force=true&w=640")!,
          size: CGSize(width: 640, height: 360)),
    ImageData(url: URL(string: "https://unsplash.com/photos/J4-xolC4CCU/download?force=true&w=640")!,
          size: CGSize(width: 640, height: 800)),
    ImageData(url: URL(string: "https://unsplash.com/photos/biggKnv1Oag/download?force=true&w=640")!,
          size: CGSize(width: 640, height: 434)),
    ImageData(url: URL(string: "https://unsplash.com/photos/MR2A97jFDAs/download?force=true&w=640")!,
          size: CGSize(width: 640, height: 959)),
    ImageData(url: URL(string: "https://unsplash.com/photos/oaCnDk89aho/download?force=true&w=640")!,
          size: CGSize(width: 640, height: 426)),
    ImageData(url: URL(string: "https://unsplash.com/photos/MOfETox0bkE/download?force=true&w=640")!,
          size: CGSize(width: 640, height: 426)),
  ]

  override var component: Component {
    Waterfall(columns: 2, spacing: 1) {
      for image in images {
        AsyncImage(image.url)
          .size(width: .fill, height: .aspectPercentage(image.size.height / image.size.width))
          .heroID(image.id)
          .tappableView {
            let detailVC = ImageDetailViewController()
            detailVC.image = image
            $0.present(detailVC)
          }
      }
    }
  }
}


class ImageDetailViewController: ComponentViewController {
  var image: ImageData! {
    didSet {
      imageView.kf.setImage(with: image.url)
      imageView.heroID = image.id
    }
  }
  let imageView = UIImageView()

  override var component: Component {
    VStack {
      imageView
        .size(width: .fill, height: .aspectPercentage(image.size.height / image.size.width))
        .tappableView {
          $0.dismiss()
        }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    transition.isUserInteractionEnabled = true
    imageView.heroModifiers = [.snapshotType(.none)]
    view.heroModifiers = [.fade, .snapshotType(.none)]
    view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(gr:))))
  }

  var initialFractionCompleted: CGFloat = 0
  var initialPosition: CGPoint = .zero
  @objc func handlePan(gr: UIPanGestureRecognizer) {
    switch gr.state {
    case .began:
      transition.beginInteractiveTransition()
      if !isBeingPresented && !isBeingDismissed {
        dismiss(animated: true, completion: nil)
      }
      initialFractionCompleted = transition.fractionCompleted
      initialPosition = transition.position(for: imageView) ?? view.convert(imageView.bounds.center, from: imageView)
    case .changed:
      guard transition.isTransitioning else { return }
      let trans = gr.translation(in: view)
      let delta = (transition.isPresenting != transition.isReversed ? -trans.y : trans.y) / view.bounds.height
      transition.apply(position: initialPosition + trans, to: imageView)
      transition.fractionCompleted = initialFractionCompleted + delta
    default:
      guard transition.isTransitioning else { return }
      let point = gr.translation(in: view) + gr.velocity(in: view)
      let delta = (transition.isPresenting != transition.isReversed ? -point.y : point.y) / view.bounds.height
      let shouldFinish = delta > 0.5
      transition.endInteractiveTransition(shouldFinish: shouldFinish)
      if isBeingPresented != shouldFinish {
        // dismissing, do not let our view handle touches anymore.
        // this allows user to swipe on the background view immediately
        view.isUserInteractionEnabled = false
      }
    }
  }
}
