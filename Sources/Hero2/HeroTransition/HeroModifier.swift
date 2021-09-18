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

  case whenOtherVC(UIViewController.Type, [HeroModifier])
  case whenPresenting([HeroModifier])
  case whenDismissing([HeroModifier])
  case whenAppearing([HeroModifier])
  case whenDisappearing([HeroModifier])
  case whenForeground([HeroModifier])
  case whenBackground([HeroModifier])
  case whenMatched([HeroModifier])
  case whenNotMatched([HeroModifier])

  case beginWith([HeroModifier])
}
