import UIKit
import BaseToolbox

open class HeroTransition: Transition {
  // MARK: - public

  public func apply(position: CGPoint, to view: UIView) {
    guard let context = contexts[view], let container = view.superview else { return }
    pause(view: context.snapshotView, animationForKey: "position")
    context.snapshotView.layer.position = container.layer.convert(
      position, to: context.snapshotView.superview!.layer.presentation())
    if let otherView = context.targetView, let otherSnap = contexts[otherView]?.snapshotView {
      pause(view: otherSnap, animationForKey: "position")
      otherSnap.layer.position = container.layer.convert(position, to: otherSnap.superview!.layer.presentation())
    }
  }

  public func position(for view: UIView) -> CGPoint? {
    guard let context = contexts[view],
      let container = view.superview,
      let position = context.snapshotView.layer.presentation()?.position
    else { return nil }
    return context.snapshotView.superview!.convert(position, to: container)
  }

  public func isMatch(view: UIView) -> Bool {
    guard let context = contexts[view] else { return false }
    return context.targetView != nil
  }

  private var contexts: [UIView: ViewTransitionContext] = [:]

  // MARK: - override

  open override func animate() {
    guard let back = backgroundView, let front = foregroundView, let container = transitionContainer else {
      fatalError()
    }
    contexts.removeAll()
    let isPresenting = isPresenting

    var animatingViews: [UIView] = []

    var frontIdToView: [String: UIView] = [:]
    var backIdToView: [String: UIView] = [:]
    let frontViews = front.viewsParticipateIn(transition: self)
    let backViews = back.viewsParticipateIn(transition: self)
    for view in frontViews {
      for heroID in view.heroIDs {
        frontIdToView[heroID] = view
      }
    }
    for view in backViews {
      for heroID in view.heroIDs {
        backIdToView[heroID] = view
      }
    }

    func findMatchedSuperview(view: UIView) -> UIView? {
      var current = view
      while let superview = current.superview, !(superview is UIWindow) {
        if let context = contexts[superview], context.targetState.skipContainer != true {
          return superview
        }
        current = superview
      }
      return nil
    }
    func processContext(isFront: Bool) {
      let views = isFront ? frontViews : backViews
      let otherVCType = isFront ? type(of: backgroundViewController!) : type(of: foregroundViewController!)
      let ourViews = isFront ? frontIdToView : backIdToView
      let otherViews = !isFront ? frontIdToView : backIdToView
      var metadata = ModifierProcessMetadata(
        containerSize: container.bounds.size,
        ourViews: ourViews,
        otherViews: otherViews,
        otherVCType: otherVCType,
        isPresenting: isPresenting,
        isForeground: isFront,
        isMatched: false)
      for view in views {
        metadata.isMatched = false
        let modifiers: [HeroModifier] = view.heroIDs.reversed().map({ .match($0) }) + (view.heroModifiers ?? [])
        let modifierState = viewStateFrom(modifiers: modifiers, metadata: &metadata)
        let other = modifierState.match.flatMap { otherViews[$0] }
        if other != nil || modifierState != ViewState(match: modifierState.match) {
          let matchedSuperview =
            (modifierState.containerType ?? .parent) == .parent ? findMatchedSuperview(view: view) : nil
          let sourceState = sourceViewStateFrom(view: view, modifierState: modifierState)
          let targetState = targetViewStateFrom(view: other ?? view, modifierState: modifierState)
          let originalState = originalViewStateFrom(view: view, sourceState: sourceState, targetState: targetState)
          contexts[view] = ViewTransitionContext(
            isFront: isFront,
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
    processContext(isFront: false)
    processContext(isFront: true)

    // generate snapshot (must be done in reverse, so that child is hidden before parent's snapshot is taken)
    for view in animatingViews.reversed() {
      switch contexts[view]?.targetState.snapshotType ?? .none {
      case .snapshotView:
        let cornerRadius = view.layer.cornerRadius
        let backgroundColor = view.backgroundColor
        view.layer.cornerRadius = 0
        view.backgroundColor = nil
        let snap = view.snapshotView(afterScreenUpdates: true)!
        snap.layer.shadowColor = view.layer.shadowColor
        snap.layer.shadowRadius = view.layer.shadowRadius
        snap.layer.shadowOffset = view.layer.shadowOffset
        snap.layer.cornerRadius = view.layer.cornerRadius
        snap.clipsToBounds = view.clipsToBounds
        snap.contentMode = .scaleAspectFill
        snap.layer.cornerRadius = cornerRadius
        view.layer.cornerRadius = cornerRadius
        snap.backgroundColor = backgroundColor
        view.backgroundColor = backgroundColor
        contexts[view]?.snapshotView = snap
      case .none:
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
      addDismissStateBlock {
        applyState(
          viewSnap: viewSnap, presented: false, shouldApplyDelay: !isPresenting, animationDuration: duration,
          viewContext: viewContext)
      }
      addPresentStateBlock {
        applyState(
          viewSnap: viewSnap, presented: true, shouldApplyDelay: isPresenting, animationDuration: duration,
          viewContext: viewContext)
      }
      addCompletionBlock { _ in
        if let placeholderView = viewContext.placeholderView {
          if placeholderView.superview != container, viewSnap.superview != nil {
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
  }

  open override func endInteractiveTransition(shouldFinish: Bool) {
    super.endInteractiveTransition(shouldFinish: shouldFinish)
  }

  open override func animationEnded(_ transitionCompleted: Bool) {
    contexts.removeAll()
    super.animationEnded(transitionCompleted)
  }
}
