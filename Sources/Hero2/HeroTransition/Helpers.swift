//
//  File.swift
//  
//
//  Created by Luke Zhao on 7/29/21.
//

import UIKit

func convertTransformToWindow(layer: CALayer) -> CATransform3D {
  var current = layer
  var trans = layer.transform
  while let superlayer = current.superlayer, !(superlayer.delegate is UIWindow) {
    trans = CATransform3DConcat(superlayer.transform, trans)
    current = superlayer
  }
  // reset translation, since translation is handled by position
  trans.m41 = 0
  trans.m42 = 0
  return trans
}

func convert(layerTransform: CATransform3D, to container: CALayer) -> CATransform3D {
  let containerTrans = convertTransformToWindow(layer: container)
  return CATransform3DConcat(layerTransform, CATransform3DInvert(containerTrans))
}

func viewStateFrom(modifiers: [HeroModifier], isPresenting: Bool, isMatched: Bool) -> ViewState {
  var state = ViewState()
  process(modifiers: modifiers, on: &state, isPresenting: isPresenting, isMatched: isMatched)
  return state
}

func process(modifiers: [HeroModifier], on state: inout ViewState, isPresenting: Bool, isMatched: Bool) {
  for modifier in modifiers {
    switch modifier {
    case .fade:
      state.alpha = 0
    case .translate(let translation):
      state.transform = CATransform3DTranslate(state.transform ?? CATransform3DIdentity,
                                               translation.x, translation.y, 0)
    case .rotate(let rotation):
      state.transform = CATransform3DRotate(state.transform ?? CATransform3DIdentity, rotation, 0, 0, 1)
    case .scale(let scale):
      state.transform = CATransform3DScale(state.transform ?? CATransform3DIdentity, scale, scale, 1)
    case .transform(let transform):
      state.transform = transform
    case .shadowOpacity(let shadowOpacity):
      state.shadowOpacity = shadowOpacity
    case .zPosition(let zPosition):
      state.zPosition = zPosition
    case .overlayColor(let color):
      state.overlayColor = color
    case .delay(let delay):
      state.delay = delay
    case .duration(let duration):
      state.duration = duration
    case .containerType(let containerType):
      state.containerType = containerType
    case .snapshotType(let snapshotType):
      state.snapshotType = snapshotType
    case .whenPresenting(let modifiers):
      if isPresenting {
        process(modifiers: modifiers, on: &state, isPresenting: isPresenting, isMatched: isMatched)
      }
    case .whenDismissing(let modifiers):
      if !isPresenting {
        process(modifiers: modifiers, on: &state, isPresenting: isPresenting, isMatched: isMatched)
      }
    case .whenMatched(let modifiers):
      if isMatched {
        process(modifiers: modifiers, on: &state, isPresenting: isPresenting, isMatched: isMatched)
      }
    case .whenNotMatched(let modifiers):
      if !isMatched {
        process(modifiers: modifiers, on: &state, isPresenting: isPresenting, isMatched: isMatched)
      }
    case.beginWith(let modifiers):
      var beginState = ViewState()
      process(modifiers: modifiers, on: &beginState, isPresenting: isPresenting, isMatched: isMatched)
      state.beginState = (state.beginState ?? ViewState())?.merge(state: beginState)
    }
  }
}

func viewStateFrom(view: UIView) -> ViewState {
  var result = ViewState()
  result.windowTransform = convertTransformToWindow(layer: view.layer)
  result.windowPosition = view.window!.convert(view.bounds.center, from: view)
  result.size = view.bounds.size
  return result
}

func viewStateFrom(view: UIView, ifExistOn modifierState: ViewState) -> ViewState {
  var viewState = ViewState()
  if modifierState.alpha != nil {
    viewState.alpha = view.alpha
  }
  if modifierState.transform != nil {
    viewState.transform = view.layer.transform
  }
  if modifierState.shadowOpacity != nil {
    viewState.shadowOpacity = CGFloat(view.layer.shadowOpacity)
  }
  if modifierState.zPosition != nil {
    viewState.zPosition = view.layer.zPosition
  }
  if let color = modifierState.overlayColor {
    viewState.overlayColor = color.withAlphaComponent(0)
  }
  return viewState
}

func targetViewStateFrom(view: UIView, modifierState: ViewState) -> ViewState {
  viewStateFrom(view: view)
    .merge(state: viewStateFrom(view: view, ifExistOn: modifierState.beginState ?? ViewState()))
    .merge(state: modifierState)
}

func sourceViewStateFrom(view: UIView, modifierState: ViewState) -> ViewState {
  viewStateFrom(view: view)
    .merge(state: viewStateFrom(view: view, ifExistOn: modifierState))
    .merge(state: modifierState.beginState ?? ViewState())
}

func originalViewStateFrom(view: UIView, sourceState: ViewState, targetState: ViewState) -> ViewState {
  viewStateFrom(view: view)
    .merge(state: viewStateFrom(view: view, ifExistOn: sourceState))
    .merge(state: viewStateFrom(view: view, ifExistOn: targetState))
}

func apply(viewState: ViewState, to view: UIView) {
  if let windowPosition = viewState.windowPosition {
    let container = view.superview!
    view.center = container.convert(windowPosition, from: container.window)
  }
  if let windowTransform = viewState.windowTransform {
    let container = view.superview!
    view.layer.transform = convert(layerTransform: windowTransform, to: container.layer)
  }
  if let size = viewState.size {
    view.bounds.size = size
  }
  if let targetAlpha = viewState.alpha {
    view.alpha = targetAlpha
  }
  if let transform = viewState.transform {
    view.layer.transform = transform
  }
  if let zPosition = viewState.zPosition {
    view.layer.zPosition = zPosition
  }
  if let shadowOpacity = viewState.shadowOpacity {
    view.layer.shadowOpacity = Float(shadowOpacity)
  }
  if let overlayColor = viewState.overlayColor {
    view.overlayView?.backgroundColor = overlayColor
  }
}

func applyState(viewSnap: UIView, presented: Bool,
                shouldApplyDelay: Bool, animationDuration: TimeInterval,
                viewContext: ViewTransitionContext) {
  let targetState = viewContext.targetState
  let state = viewContext.isFront == presented ? viewContext.sourceState : targetState
  let delay = targetState.delay ?? 0
  let duration = targetState.duration ?? 0
  if shouldApplyDelay, delay > 0 || duration > 0 {
    let relativeDuration = duration > 0 ? duration / animationDuration : 1 - delay / animationDuration
    UIView.animateKeyframes(withDuration: animationDuration, delay: 0, options: [], animations: {
      UIView.addKeyframe(withRelativeStartTime: delay / animationDuration, relativeDuration: relativeDuration) {
        apply(viewState: state, to: viewSnap)
      }
    }, completion: nil)
  } else {
    apply(viewState: state, to: viewSnap)
  }
}
