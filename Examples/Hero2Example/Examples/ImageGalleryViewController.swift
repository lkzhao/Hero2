//
//  ImageGalleryViewController.swift
//  Hero2Example
//
//  Created by Luke Zhao on 8/1/21.
//  Copyright © 2021 Luke Zhao. All rights reserved.
//

import BaseToolbox
import Hero2
import Kingfisher
import UIComponent
import UIKit

class ImageGalleryViewController: ComponentViewController {
    let images = ImageData.testImages

    override var component: any Component {
        Waterfall(columns: 2, spacing: 1) {
            for image in images {
                AsyncImage(image.url)
                    .size(width: .fill, height: .aspectPercentage(image.size.height / image.size.width))
                    .heroID(image.id)
                    .tappableView { [unowned self] in
                        self.didTap(image: image)
                    }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let image = toBePresentedImage {
            toBePresentedImage = nil
            present(image: image)
        }
    }

    var toBePresentedImage: ImageData?
    func didTap(image: ImageData) {
        if presentingViewController != nil {
            toBePresentedImage = image
        } else {
            present(image: image)
        }
    }

    func present(image: ImageData) {
        let detailVC = ImageDetailViewController()
        detailVC.image = image
        present(detailVC, animated: true, completion: nil)
    }
}

class ImageDetailViewController: ComponentViewController {
    var image: ImageData! {
        didSet {
            imageView.kf.setImage(with: image.url)
            imageView.heroID = image.id
        }
    }
    let imageView = UIImageView()
    lazy var panGR = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gr:)))

    override var component: any Component {
        VStack(justifyContent: .center) {
            imageView.size(width: .fill, height: .aspectPercentage(image.size.height / image.size.width)).inset(30)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        transition.isUserInteractionEnabled = true
        //    transition.duration = 1
        imageView.shadowColor = .black.withAlphaComponent(0.2)
        imageView.shadowRadius = 8
        imageView.shadowOpacity = 1
        imageView.shadowOffset = .zero
        view.heroModifiers = [.fade]
        panGR.delegate = self
        view.addGestureRecognizer(panGR)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    @objc func didTap() {
        dismiss(animated: true, completion: nil)
    }

    var initialFractionCompleted: CGFloat = 0
    var initialPosition: CGPoint = .zero
    @objc func handlePan(gr: UIPanGestureRecognizer) {
        guard let transition = transition as? HeroTransition else { return }
        func progressFrom(offset: CGPoint) -> CGFloat {
            let progress = (offset.x + offset.y) / ((view.bounds.height + view.bounds.width) / 4)
            return (transition.isPresenting != transition.isReversed ? -progress : progress)
        }
        switch gr.state {
        case .began:
            transition.beginInteractiveTransition()
            if !isBeingPresented, !isBeingDismissed {
                dismiss(animated: true, completion: nil)
            }
            initialFractionCompleted = transition.fractionCompleted
            initialPosition = transition.position(for: imageView) ?? view.convert(imageView.bounds.center, from: imageView)
        case .changed:
            let translation = gr.translation(in: view)
            let progress = progressFrom(offset: translation)
            transition.apply(position: initialPosition + translation, to: imageView)
            transition.fractionCompleted = (initialFractionCompleted + progress).clamp(0, 1)
        default:
            let combinedOffset = gr.translation(in: view) + gr.velocity(in: view)
            let progress = progressFrom(offset: combinedOffset)
            let shouldFinish = progress > 0.5
            transition.endInteractiveTransition(shouldFinish: shouldFinish)
            if isBeingPresented != shouldFinish {
                // dismissing, do not let our view handle touches anymore.
                // this allows user to swipe on the background view immediately
                view.isUserInteractionEnabled = false
            }
        }
    }
}

extension ImageDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let velocity = panGR.velocity(in: nil)
        // only allow right and down swipe
        return velocity.x > abs(velocity.y) || velocity.y > abs(velocity.x)
    }
}
