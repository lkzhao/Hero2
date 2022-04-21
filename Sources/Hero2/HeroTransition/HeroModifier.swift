//
//  File.swift
//
//
//  Created by Luke Zhao on 7/25/21.
//

import UIKit

public enum SnapshotType {
    case none
    case snapshotView
}

public enum ContainerType {
    case parent
    case global
}

public enum HeroModifier {
    case fade

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

    // force the current view to participage in the transition
    // it will be independent during the transition, and won't be captured by the superview's snapshot.
    case forceTransition

    case containerType(ContainerType)
    case snapshotType(SnapshotType)

    case _beginWith([HeroModifier])
    case _process((ModifierProcessMetadata) -> [HeroModifier])

    public static let snapshotView: HeroModifier = .snapshotType(.snapshotView)
    public static let globalContainer: HeroModifier = .containerType(.global)
    public static func translate(_ point: CGPoint) -> HeroModifier {
        .transform(CATransform3DMakeTranslation(point.x, point.y, 0))
    }
    public static func translate(x: CGFloat = 0, y: CGFloat = 0, z: CGFloat = 0) -> HeroModifier {
        .transform(CATransform3DMakeTranslation(x, y, z))
    }
    public static func translatePercentage(_ point: CGPoint) -> HeroModifier {
        ._process {
            [.transform(CATransform3DMakeTranslation(point.x * $0.containerSize.width, point.y * $0.containerSize.height, 0))]
        }
    }
    public static func translatePercentage(x: CGFloat = 0, y: CGFloat = 0) -> HeroModifier {
        .translatePercentage(CGPoint(x: x, y: y))
    }
    public static func rotate(_ angle: CGFloat, x: CGFloat = 0, y: CGFloat = 0, z: CGFloat = 1) -> HeroModifier {
        .transform(CATransform3DMakeRotation(angle, x, y, z))
    }
    public static func scale(_ amount: CGFloat) -> HeroModifier {
        .transform(CATransform3DMakeScale(amount, amount, 1))
    }
    public static func scale(x: CGFloat = 1, y: CGFloat = 1, z: CGFloat = 1) -> HeroModifier {
        .transform(CATransform3DMakeScale(x, y, z))
    }
    public static func beginWith(_ modifiers: HeroModifier...) -> HeroModifier {
        ._beginWith(modifiers)
    }
    public static func when(_ checker: @escaping (ModifierProcessMetadata) -> Bool, _ modifiers: [HeroModifier]) -> HeroModifier {
        ._process {
            checker($0) ? modifiers : []
        }
    }
    public static func when(_ checker: @escaping (ModifierProcessMetadata) -> Bool, _ modifiers: HeroModifier...) -> HeroModifier {
        .when(checker, modifiers)
    }
    public static func whenOtherVCTypeMatches(_ type: UIViewController.Type, _ modifiers: HeroModifier...) -> HeroModifier {
        .when({ $0.otherVCType == type }, modifiers)
    }
    public static func whenOtherVCTypeDoesntMatch(_ type: UIViewController.Type, _ modifiers: HeroModifier...) -> HeroModifier {
        .when({ $0.otherVCType != type }, modifiers)
    }
    public static func whenAnotherViewIsMatched(_ view: UIView, _ modifiers: HeroModifier...) -> HeroModifier {
        .when(
            { [weak view] metadata in
                view?.heroIDs.contains { metadata.otherViews[$0] != nil } == true
            },
            modifiers
        )
    }
    public static func whenAnotherViewIsNotMatched(_ view: UIView, _ modifiers: HeroModifier...) -> HeroModifier {
        .when(
            { [weak view] metadata in
                view?.heroIDs.contains { metadata.otherViews[$0] != nil } != true
            },
            modifiers
        )
    }
    public static func whenMatched(_ modifiers: HeroModifier...) -> HeroModifier {
        .when({ $0.isMatched }, modifiers)
    }
    public static func whenNotMatched(_ modifiers: HeroModifier...) -> HeroModifier {
        .when({ !$0.isMatched }, modifiers)
    }
    public static func whenPresenting(_ modifiers: HeroModifier...) -> HeroModifier {
        .when({ $0.isPresenting }, modifiers)
    }
    public static func whenDismissing(_ modifiers: HeroModifier...) -> HeroModifier {
        .when({ !$0.isPresenting }, modifiers)
    }
    public static func whenAppearing(_ modifiers: HeroModifier...) -> HeroModifier {
        .when({ $0.isPresenting == $0.isForeground }, modifiers)
    }
    public static func whenDisappearing(_ modifiers: HeroModifier...) -> HeroModifier {
        .when({ $0.isPresenting != $0.isForeground }, modifiers)
    }
    public static func whenForeground(_ modifiers: HeroModifier...) -> HeroModifier {
        .when({ $0.isForeground }, modifiers)
    }
    public static func whenBackground(_ modifiers: HeroModifier...) -> HeroModifier {
        .when({ !$0.isForeground }, modifiers)
    }
}
