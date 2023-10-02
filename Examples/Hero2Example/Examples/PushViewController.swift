//
//  PushViewController.swift
//  Hero2Example
//
//  Created by Luke Zhao on 7/29/21.
//  Copyright © 2021 Luke Zhao. All rights reserved.
//

import BaseToolbox
import Hero2
import UIComponent
import UIKit

class PushViewController: ComponentViewController {
    override var component: any Component {
        VStack(spacing: 8, justifyContent: .center, alignItems: .center) {
            Text("Present Detail VC").textColor(.systemBlue)
                .tappableView {
                    $0.push(PushDetailViewController())
                }
        }
        .size(width: .fill).inset(20)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.heroModifiers = [.overlayColor(UIColor.black.withAlphaComponent(0.2))]
    }
}

class PushDetailViewController: ComponentViewController {
    override var component: any Component {
        VStack(spacing: 8) {
            Text("PushDetailViewController")
        }
        .inset(20)
    }

    lazy var panGR = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gr:)))
    override func viewDidLoad() {
        super.viewDidLoad()
        // allow interruptible transition
        transition.isUserInteractionEnabled = true
        panGR.delegate = self
        view.shadowRadius = 20
        view.shadowOffset = .zero
        view.backgroundColor = .systemGroupedBackground
        view.addGestureRecognizer(panGR)
        view.heroModifiers = [.translatePercentage(x: 1), .beginWith(.shadowOpacity(0.5))]
    }

    var initialFractionCompleted: CGFloat = 0
    @objc func handlePan(gr: UIPanGestureRecognizer) {
        func progressFrom(offset: CGPoint) -> CGFloat {
            let progress = offset.x / view.bounds.width
            return (transition.isPresenting != transition.isReversed ? -progress : progress)
        }
        switch gr.state {
        case .began:
            transition.beginInteractiveTransition()
            if !isBeingDismissed, !isBeingPresented {
                view.dismiss()
            }
            initialFractionCompleted = transition.fractionCompleted
        case .changed:
            let trans = gr.translation(in: view)
            let progress = progressFrom(offset: trans)
            transition.fractionCompleted = initialFractionCompleted + progress
        default:
            let combinedOffset = gr.translation(in: view) + gr.velocity(in: view)
            let progress = progressFrom(offset: combinedOffset)
            let shouldFinish = progress > 0.3
            transition.endInteractiveTransition(shouldFinish: shouldFinish)
            if isBeingPresented != shouldFinish {
                // dismissing, do not let our view handle touches anymore.
                // this allows user to swipe on the background view immediately
                view.isUserInteractionEnabled = false
            }
        }
    }
}

extension PushDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let velocity = panGR.velocity(in: nil)
        return velocity.x > abs(velocity.y)
    }
}
