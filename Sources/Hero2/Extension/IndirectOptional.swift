//
//  File.swift
//  
//
//  Created by Luke Zhao on 7/30/21.
//

import Foundation

@propertyWrapper
enum IndirectOptional<T> {
  case none
  indirect case some(T)
  init(wrappedValue: T?) {
    if let wrappedValue = wrappedValue {
      self = .some(wrappedValue)
    } else {
      self = .none
    }
  }
  var wrappedValue: T? {
    get {
      switch self {
      case .none: return nil
      case .some(let value): return value
      }
    }
    set {
      if let newValue = newValue {
        self = .some(newValue)
      } else {
        self = .none
      }
    }
  }
}

extension IndirectOptional: Equatable where T: Equatable {
  
}
