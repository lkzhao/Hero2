import UIKit

public protocol TransitionProvider: UIViewController {
    func transitionFor(presenting: Bool, otherViewController: UIViewController) -> BaseTransition?
}

public class TransitionCoordinator: NSObject {
    public static let shared = TransitionCoordinator()

    public var defaultTransition: BaseTransition = HeroTransition()
    public private(set) var currentTransition: BaseTransition?
    public var isTransitioning: Bool {
        currentTransition?.isTransitioning == true
    }
    public var isAnimating: Bool {
        currentTransition?.isAnimating == true
    }

    private func setupTransition(
        from: UIViewController,
        to: UIViewController,
        isPresenting: Bool,
        navigationController: UINavigationController?
    ) {
        let transitionProvider = (isPresenting ? to : from) as? TransitionProvider
        let transition =
            transitionProvider?.transitionFor(presenting: isPresenting, otherViewController: isPresenting ? from : to)
            ?? defaultTransition
        self.currentTransition = transition
        transition.setupTransition(isPresenting: isPresenting, navigationController: navigationController)
    }
}

extension TransitionCoordinator: UIViewControllerTransitioningDelegate {
    private var interactiveTransitioning: UIViewControllerInteractiveTransitioning? {
        currentTransition
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source _: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        setupTransition(from: presenting, to: presented, isPresenting: true, navigationController: nil)
        return currentTransition
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let toVC = dismissed.presentingViewController else { return nil }
        setupTransition(from: dismissed, to: toVC, isPresenting: false, navigationController: nil)
        return currentTransition
    }

    public func interactionControllerForDismissal(using _: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning?
    {
        interactiveTransitioning
    }

    public func interactionControllerForPresentation(using _: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning?
    {
        interactiveTransitioning
    }
}

extension TransitionCoordinator: UINavigationControllerDelegate {
    public func navigationController(
        _: UINavigationController,
        interactionControllerFor _: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        interactiveTransitioning
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from: UIViewController,
        to: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        setupTransition(from: from, to: to, isPresenting: operation == .push, navigationController: navigationController)
        return currentTransition
    }
}
