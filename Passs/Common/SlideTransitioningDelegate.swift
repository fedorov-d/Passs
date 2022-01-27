//
//  SlideTransitioningDelegate.swift
//  Passs
//
//  Created by Dmitry Fedorov on 21.01.2022.
//

import UIKit

class SlideTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideTransitioning(action: .present)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideTransitioning(action: .dismiss)
    }
}

private class SlideTransitioning: NSObject, UIViewControllerAnimatedTransitioning {

    enum Action {
        case present, dismiss
    }

    private let action: Action

    init(action: Action) {
        self.action = action
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    weak var toViewController: UIViewController?

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else { return }

        let toView = transitionContext.view(forKey: .to)
        let fromView = transitionContext.view(forKey: .from)

        let containerView = transitionContext.containerView

        let containerFrame = containerView.frame
        var toStartFrame = transitionContext.initialFrame(for: toVC)
        let toFinalFrame = transitionContext.finalFrame(for: toVC)
        var fromFinalFrame = transitionContext.finalFrame(for: fromVC)

        var backgroundView = self.backgroundView
        if self.action == .present {
            // Modify the frame of the presented view so that it starts
            // offscreen at the lower-right corner of the container.
            toStartFrame.origin.y = containerFrame.size.height;
            toStartFrame.size = toFinalFrame.size;
            backgroundView.frame = toFinalFrame
            containerView.addSubview(backgroundView)
            toViewController = toVC
        } else {
            // Modify the frame of the dismissed view so it ends in
            // the lower-right corner of the container view.
            if let view = containerView.viewWithTag(tag) {
                backgroundView = view
            }
            fromFinalFrame = CGRect(x: 0,
                                    y: containerFrame.size.height,
                                    width: containerFrame.size.width,
                                    height: containerFrame.height);
        }

        // Always add the "to" view to the container.
        // And it doesn't hurt to set its start frame.
        if let toView = toView {
            containerView.addSubview(toView)
            toView.frame = toStartFrame
        }

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext)) {
                if self.action == .present {
                    backgroundView.alpha = 1.0
                    toView?.frame = toFinalFrame
                } else {
                    backgroundView.alpha = 0.0
                    fromView?.frame = fromFinalFrame
                }
            } completion: { completed in
                let success = !transitionContext.transitionWasCancelled
                if (self.action == .present && !success) || (self.action == .dismiss && success) {
                    toView?.removeFromSuperview()
                }
                transitionContext.completeTransition(success)
            }
    }

    private lazy var backgroundView: UIView = {
        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.15);
        backgroundView.alpha = 0.0
        backgroundView.tag = tag
        return backgroundView
    }()

    private let tag = 34234
}
