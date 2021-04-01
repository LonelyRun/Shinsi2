import UIKit

class BaseViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    var isPopover: Bool = false
    
    // Manage popover style
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let presentingVC = segue.destination.presentationController {
            presentingVC.delegate = self
        }
    }
    
    //Hide navigationBar when viewController is in the popover
    func presentationController(_ presentationController: UIPresentationController,
                                willPresentWithAdaptiveStyle style: UIModalPresentationStyle,
                                transitionCoordinator: UIViewControllerTransitionCoordinator?) {
        if let nvc = presentationController.presentedViewController as? UINavigationController {
            nvc.navigationBar.isHidden = style == .none || style == .popover
            nvc.popoverPresentationController?.backgroundColor = .white
            if let vc = nvc.topViewController as? BaseViewController {
                vc.isPopover = style == .none || style == .popover
            }
        }
    }
}
