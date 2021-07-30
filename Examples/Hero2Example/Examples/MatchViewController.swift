//
//  MatchViewController.swift
//  Hero2Example
//
//  Created by Luke Zhao on 7/25/21.
//  Copyright © 2021 Luke Zhao. All rights reserved.
//

import UIKit
import Hero2
import UIComponent

struct Shape: Identifiable {
  let id: String
  let image: UIImage
  let color: UIColor
  let transform: CGAffineTransform
  init(name: String, color: UIColor, transform: CGAffineTransform) {
    self.id = name
    self.image = UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: 150))!
    self.color = color
    self.transform = transform
  }
}
class MatchViewController: ComponentViewController {
  var shapes: [Shape] = [
    Shape(name: "rectangle", color: .systemPurple, transform: .identity.translatedBy(x: 100, y: -200).scaledBy(x: 0.4, y: 0.4).rotated(by: .pi * 1.1)),
    Shape(name: "square", color: .systemRed, transform: .identity.translatedBy(x: -100, y: -200).scaledBy(x: 0.7, y: 0.7).rotated(by: .pi * -0.33)),
    Shape(name: "circle", color: .systemGreen, transform: .identity.translatedBy(x: 50, y: 200).scaledBy(x: 1.1, y: 1.1)),
    Shape(name: "star", color: .systemOrange, transform: .identity.translatedBy(x: -50, y: 0).rotated(by: 0.2)),
  ]
  override var component: Component {
    VStack(spacing: 8) {
      ZStack {
        for shape in shapes {
          Image(shape.image).tintColor(shape.color).contentMode(.scaleAspectFit).heroID(shape.id).heroModifiers([.whenNotMatched([.fade])]).size(width: .fill, height: .fill).tappableView {
            let vc = MatchDetailViewController()
            vc.shape = shape
            $0.present(vc)
          }.size(width: 150, height: 150)
          .transform(shape.transform)
//          .backgroundColor(.lightGray.withAlphaComponent(0.2)).cornerRadius(10)
        }
      }.size(width: .fill, height: .aspectPercentage(16/9)).view()
      .clipsToBounds(true)
      .heroID("canvas")
      .heroModifiers([.containerType(.global), .zPosition(1), .beginWith([.zPosition(1)])])
      .transform(.identity.rotated(by: 0.1))
      .backgroundColor(.systemGroupedBackground).cornerRadius(20).clipsToBounds(true)
      Spacer()
      HStack(justifyContent: .spaceEvenly) {
        Image(systemName: "chevron.left").tintColor(.systemBlue).tappableView {
          $0.dismiss()
        }.heroID("back-button")
        Image(systemName: "rectangle").tintColor(.systemBlue)
          .heroModifiers([.scale(0.2), .fade,
                          .whenPresenting([.delay(0.0)]),
                          .whenDismissing([.delay(0.2)]),
                          .duration(0.3),
          ])
        Image(systemName: "square").tintColor(.systemBlue)
          .heroModifiers([.scale(0.2), .fade,
                          .whenPresenting([.delay(0.1)]),
                          .whenDismissing([.delay(0.1)]),
                          .duration(0.3),
          ])
        Image(systemName: "circle").tintColor(.systemBlue)
          .heroModifiers([.scale(0.2), .fade,
                          .whenPresenting([.delay(0.2)]),
                          .whenDismissing([.delay(0.0)]),
                          .duration(0.3),
          ])
      }
    }.inset(20)
  }
}


class MatchDetailViewController: ComponentViewController {
  var shape: Shape!
  override var component: Component {
    VStack(spacing: 20) {
      ZStack {
        Image(shape.image).size(width: 200, height: 200).heroID(shape.id).tintColor(shape.color).contentMode(.scaleAspectFit)
      }.size(width: .fill, height: .aspectPercentage(14/9)).tappableView {
        $0.dismiss()
      }.heroID("canvas").backgroundColor(.systemGroupedBackground).cornerRadius(20).clipsToBounds(true)
      HStack(spacing: 10) {
        for _ in 0..<10 {
          Space(width: 64, height: 64).view().backgroundColor(.systemGray2).cornerRadius(8)
        }
      }.inset(h: 20).scrollView().heroModifiers([
                                                  .fade,
//                                                  .transform(CATransform3DScale(CATransform3DTranslate(CATransform3DIdentity, 0, 44, 0), 1, 0.2, 1))
      ]).inset(h: -20)
      Spacer()
      HStack(justifyContent: .spaceEvenly) {
        Image(systemName: "chevron.left").tintColor(.systemBlue).tappableView {
          $0.dismiss()
        }.heroID("back-button")
      }
    }.inset(20)
  }
  override func viewDidLoad() {
    super.viewDidLoad()
//    view.backgroundColor = .green
//    view.heroModifiers = [.fade]
  }
}
