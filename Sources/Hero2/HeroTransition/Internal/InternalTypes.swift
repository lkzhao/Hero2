import UIKit

struct ViewTransitionContext {
  var isFront: Bool
  var targetView: UIView?
  var matchedSuperView: UIView?
  var snapshotView: UIView!
  var placeholderView: UIView?
  var sourceState: ViewState
  var targetState: ViewState
  var originalState: ViewState
}

struct ViewState: Equatable {
  var match: String? = nil
  var containerType: ContainerType? = nil
  var snapshotType: SnapshotType? = nil
  var windowTransform: CATransform3D? = nil
  var windowPosition: CGPoint? = nil
  var size: CGSize? = nil
  var alpha: CGFloat? = nil
  var transform: CATransform3D? = nil
  var delay: TimeInterval? = nil
  var duration: TimeInterval? = nil
  var shadowOpacity: CGFloat? = nil
  var cornerRadius: CGFloat? = nil
  var overlayColor: UIColor? = nil
  var zPosition: CGFloat? = nil
  @IndirectOptional var beginState: ViewState? = nil
}

extension ViewState {
  func merge(state: ViewState) -> ViewState {
    ViewState(match: state.match ?? match,
              containerType: state.containerType ?? containerType,
              snapshotType: state.snapshotType ?? snapshotType,
              windowTransform: state.windowTransform ?? windowTransform,
              windowPosition: state.windowPosition ?? windowPosition,
              size: state.size ?? size,
              alpha: state.alpha ?? alpha,
              transform: state.transform ?? transform,
              delay: state.delay ?? delay,
              duration: state.duration ?? duration,
              shadowOpacity: state.shadowOpacity ?? shadowOpacity,
              cornerRadius: state.cornerRadius ?? cornerRadius,
              overlayColor: state.overlayColor ?? overlayColor,
              zPosition: state.zPosition ?? zPosition,
              beginState: state.beginState ?? beginState)
  }
}
