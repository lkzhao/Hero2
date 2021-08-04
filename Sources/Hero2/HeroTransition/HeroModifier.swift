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

public enum HeroModifier: Equatable {
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
  
  case match(String)

  case containerType(ContainerType)
  case snapshotType(SnapshotType)
  
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
