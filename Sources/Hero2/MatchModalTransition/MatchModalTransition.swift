//
//  File.swift
//  
//
//  Created by Luke Zhao on 10/24/21.
//

import Foundation

class MatchModalTransition: Transition {
  override func animate() -> (dismissed: () -> Void, presented: () -> Void, completed: (Bool) -> Void) {
    return ({}, {}, {_ in })
  }
}