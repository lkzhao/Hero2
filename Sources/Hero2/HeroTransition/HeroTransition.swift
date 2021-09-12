import UIKit

open class HeroTransition: Transition {
  // MARK: - public
  
  public func apply(position: CGPoint, to view: UIView) {
    guard let context = contexts[view], let container = view.superview else { return }
    pause(view: context.snapshotView, animationForKey: "position")
    context.snapshotView.layer.position = container.convert(position, to: context.snapshotView.superview!)
    if let otherView = context.targetView, let otherSnap = contexts[otherView]?.snapshotView {
      pause(view: otherSnap, animationForKey: "position")
      otherSnap.layer.position = container.convert(position, to: otherSnap.superview!)
    }
  }
  
  public func position(for view: UIView) -> CGPoint? {
    guard let context = contexts[view],
          let container = view.superview,
          let position = context.snapshotView.layer.presentation()?.position else { return nil }
    return context.snapshotView.superview!.convert(position, to: container)
  }
    
  public func isMatch(view: UIView) -> Bool {
    guard let context = contexts[view] else { return false }
    return context.targetView != nil
  }
  
  // MARK: - private
  
  private var pausedAnimations: [UIView: [String: CAAnimation]] = [:]
  private var contexts: [UIView: ViewTransitionContext] = [:]
  
  private func pause(view: UIView, animationForKey key: String) {
    guard pausedAnimations[view]?[key] == nil, let anim = view.layer.animation(forKey: key) else { return }
    pausedAnimations[view, default: [:]][key] = anim
    view.layer.removeAnimation(forKey: key)
  }
  
  // MARK: - override

  open override func animate() -> (dismissed: () -> Void, presented: () -> Void, completed: (Bool) -> Void) {
    guard let back = backgroundView, let front = foregroundView, let container = transitionContainer else {
      fatalError()
    }
    pausedAnimations.removeAll()
    contexts.removeAll()
    let isPresenting = isPresenting
    
    var dismissedOperations: [() -> Void] = []
    var presentedOperations: [() -> Void] = []
    var completionOperations: [(Bool) -> Void] = []
    
    var animatingViews: [UIView] = []
    
    var frontIdToView: [String: UIView] = [:]
    var backIdToView: [String: UIView] = [:]
    for view in front.flattendSubviews {
      for heroID in view.heroIDs {
        frontIdToView[heroID] = view
      }
    }
    for view in back.flattendSubviews {
      for heroID in view.heroIDs {
        backIdToView[heroID] = view
      }
    }
    
    func findMatchedSuperview(view: UIView) -> UIView? {
      var current = view
      while let superview = current.superview, !(superview is UIWindow) {
        if contexts[superview] != nil {
          return superview
        }
        current = superview
      }
      return nil
    }
    func processContext(views: [UIView], isFront: Bool) {
      for view in views {
        let modifiers: [HeroModifier] = view.heroIDs.reversed().map({ .match($0) }) + (view.heroModifiers ?? [])
        let ourViews = isFront ? frontIdToView : backIdToView
        let otherViews = !isFront ? frontIdToView : backIdToView
        let modifierState = viewStateFrom(modifiers: modifiers,
                                          view: view,
                                          containerSize: container.bounds.size,
                                          ourViews: ourViews,
                                          otherViews: otherViews,
                                          isPresenting: isPresenting,
                                          isForeground: isFront)
        let other = modifierState.match.flatMap { otherViews[$0] }
        if other != nil || modifierState != ViewState(match: modifierState.match) {
          let matchedSuperview = (modifierState.containerType ?? .parent) == .parent ? findMatchedSuperview(view: view) : nil
          let sourceState = sourceViewStateFrom(view: view, modifierState: modifierState)
          let targetState = targetViewStateFrom(view: other ?? view, modifierState: modifierState)
          let originalState = originalViewStateFrom(view: view, sourceState: sourceState, targetState: targetState)
          contexts[view] = ViewTransitionContext(isFront: isFront,
                                                 targetView: other,
                                                 matchedSuperView: matchedSuperview,
                                                 snapshotView: nil,
                                                 sourceState: sourceState,
                                                 targetState: targetState,
                                                 originalState: originalState)
          animatingViews.append(view)
        }
      }
    }
    processContext(views: back.flattendSubviews, isFront: false)
    processContext(views: front.flattendSubviews, isFront: true)
    
    // generate snapshot (must be done in reverse, so that child is hidden before parent's snapshot is taken)
    for view in animatingViews.reversed() {
      if (contexts[view]?.targetState.snapshotType ?? .default) == .default {
        let cornerRadius = view.layer.cornerRadius
        view.layer.cornerRadius = 0
        let snap = view.snapshotView(afterScreenUpdates: true)!
        snap.layer.shadowColor = view.layer.shadowColor
        snap.layer.shadowRadius = view.layer.shadowRadius
        snap.layer.shadowOffset = view.layer.shadowOffset
        snap.layer.cornerRadius = view.layer.cornerRadius
        snap.clipsToBounds = view.clipsToBounds
        snap.contentMode = .scaleAspectFill
        snap.layer.cornerRadius = cornerRadius
        view.layer.cornerRadius = cornerRadius
        contexts[view]?.snapshotView = snap
      } else {
        let placeholderView = UIView()
        view.superview?.insertSubview(placeholderView, aboveSubview: view)
        contexts[view]?.snapshotView = view
        contexts[view]?.placeholderView = placeholderView
      }
      if contexts[view]?.targetState.overlayColor != nil || contexts[view]?.sourceState.overlayColor != nil {
        contexts[view]?.snapshotView?.addOverlayView()
      }
      view.isHidden = true
    }
    
    let duration = animator!.duration
    for view in animatingViews {
      let viewContext = contexts[view]!
      let viewSnap = viewContext.snapshotView!
      let viewContainer = viewContext.matchedSuperView.flatMap { contexts[$0]?.snapshotView } ?? container
      viewContainer.addSubview(viewSnap)
      viewSnap.isHidden = false
      dismissedOperations.append {
        applyState(viewSnap: viewSnap, presented: false, shouldApplyDelay: !isPresenting, animationDuration: duration, viewContext: viewContext)
      }
      presentedOperations.append {
        applyState(viewSnap: viewSnap, presented: true, shouldApplyDelay: isPresenting, animationDuration: duration, viewContext: viewContext)
      }
      completionOperations.append { _ in
        if let placeholderView = viewContext.placeholderView {
          if placeholderView.superview != container {
            placeholderView.superview?.insertSubview(viewSnap, belowSubview: placeholderView)
          }
          placeholderView.removeFromSuperview()
          viewSnap.removeOverlayView()
          applyViewState(viewContext.originalState, to: viewSnap)
        } else {
          viewSnap.removeFromSuperview()
          view.isHidden = false
        }
      }
    }
    
    let dismissed: () -> Void = {
      for op in dismissedOperations {
        op()
      }
    }

    let presented: () -> Void = {
      for op in presentedOperations {
        op()
      }
    }
    
    let completion: (Bool) -> Void = { finished in
      for op in completionOperations {
        op(finished)
      }
    }
    return (dismissed, presented, completion)
  }
  
  open override func endInteractiveTransition(shouldFinish: Bool) {
    for (view, animations) in pausedAnimations {
      for (key, anim) in animations {
        view.layer.add(anim, forKey: key)
      }
    }
    pausedAnimations.removeAll()
    super.endInteractiveTransition(shouldFinish: shouldFinish)
  }
  
  open override func animationEnded(_ transitionCompleted: Bool) {
    pausedAnimations.removeAll()
    contexts.removeAll()
    super.animationEnded(transitionCompleted)
  }
}
