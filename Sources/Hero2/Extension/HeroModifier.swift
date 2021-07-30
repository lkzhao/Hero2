//
//  File.swift
//  
//
//  Created by Luke Zhao on 7/25/21.
//

import UIKit

public enum HeroModifier: Equatable {
  case fade
  case translate(CGPoint)
  case rotate(CGFloat)
  case scale(CGFloat)
  case transform(CATransform3D)
  case delay(TimeInterval)
  case duration(TimeInterval)
  case zPosition(CGFloat)
  case shadowOpacity(CGFloat)

  case overlayColor(UIColor)

  case containerType(ContainerType)
  case snapshotType(SnapshotType)
  
  case whenPresenting([HeroModifier])
  case whenDismissing([HeroModifier])
  case whenMatched([HeroModifier])
  case whenNotMatched([HeroModifier])
  
  case beginWith([HeroModifier])
}
