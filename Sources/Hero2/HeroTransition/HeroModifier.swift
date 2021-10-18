//
//  File.swift
//
//
//  Created by Luke Zhao on 7/25/21.
//

import UIKit

public enum SnapshotType {
  case `default`
  case none
}

public enum ContainerType {
  case parent
  case global
}

public enum HeroModifier {
  case fade
  case translate(CGPoint)
  case translatePercentage(CGPoint)
  case rotate(CGFloat)
  case scale(CGFloat)
  case transform(CATransform3D)
  case delay(TimeInterval)
  case duration(TimeInterval)
  case zPosition(CGFloat)
  case shadowOpacity(CGFloat)

  case overlayColor(UIColor)
  case backgroundColor(UIColor)

  case match(String)

  // Cause the size change to be a scale transform instead of a bounds.size update.
  // This could be useful when animating views that don't support size change with UIViewPropertyAnimator.
  // AVPlayerLayer for example, will stop animating when the animator is paused.
  case scaleSize

  // Skip treating this view as a container view even if it is being animated.
  // This is useful when the view is transforming and you don't want the transform
  // to influence any animating child view
  case skipContainer

  case containerType(ContainerType)
  case snapshotType(SnapshotType)

  case when((ModifierProcessMetadata) -> Bool, [HeroModifier])
  case whenMatched([HeroModifier])
  case whenNotMatched([HeroModifier])

  case beginWith([HeroModifier])

  public static func whenOtherVCTypeMatches(_ type:UIViewController.Type, _ modifiers: [HeroModifier]) -> HeroModifier {
    .when({ $0.otherVCType == type }, modifiers)
  }
  public static func whenAnotherViewIsMatched(_ view: UIView, _ modifiers: [HeroModifier]) -> HeroModifier {
    .when({ [weak view] metadata in
      view?.heroIDs.contains { metadata.otherViews[$0] != nil } == true
    }, modifiers)
  }
  public static func whenPresenting(_ modifiers: [HeroModifier]) -> HeroModifier {
    .when({ $0.isPresenting }, modifiers)
  }
  public static func whenDismissing(_ modifiers: [HeroModifier]) -> HeroModifier {
    .when({ !$0.isPresenting }, modifiers)
  }
  public static func whenAppearing(_ modifiers: [HeroModifier]) -> HeroModifier {
    .when({ $0.isPresenting == $0.isForeground }, modifiers)
  }
  public static func whenDisappearing(_ modifiers: [HeroModifier]) -> HeroModifier {
    .when({ $0.isPresenting != $0.isForeground }, modifiers)
  }
  public static func whenForeground(_ modifiers: [HeroModifier]) -> HeroModifier {
    .when({ $0.isForeground }, modifiers)
  }
  public static func whenBackground(_ modifiers: [HeroModifier]) -> HeroModifier {
    .when({ !$0.isForeground }, modifiers)
  }
}
