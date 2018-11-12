import UIKit

class BaseViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    // Manage popover style
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let presentingVC = segue.destination.presentationController {
            presentingVC.delegate = self
        }
    }
    
    func presentationController(_ presentationController: UIPresentationController, willPresentWithAdaptiveStyle style: UIModalPresentationStyle, transitionCoordinator: UIViewControllerTransitionCoordinator?) {
        if let nvc = presentationController.presentedViewController as? UINavigationController {
            nvc.navigationBar.isHidden = style == .none || style == .popover
            nvc.popoverPresentationController?.backgroundColor = .white
        }
    }
}
