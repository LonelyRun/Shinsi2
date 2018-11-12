import UIKit

import SVProgressHUD
import SDWebImage

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        setDefaultAppearance()
        setDefaultHudAppearance()
        Defaults.Search.categories.map{ [$0:true] }.forEach{ UserDefaults.standard.register(defaults: $0) }
        
        #if DEBUG
        //RealmManager.shared.deleteSearchHistory()
        //SDImageCache.shared().clearMemory()
        //SDImageCache.shared().clearDisk()
        #endif
        
        return true
    }
    
    func setDefaultAppearance() {
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white,
                                                                 NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)]
        UINavigationBar.appearance().tintColor = kMainColor
        UINavigationBar.appearance().barStyle = .blackTranslucent
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = #colorLiteral(red: 0.09966118171, green: 0.5230001833, blue: 0.8766457805, alpha: 1)
    }
    
    func setDefaultHudAppearance() {
        SVProgressHUD.setCornerRadius(10)
        SVProgressHUD.setMinimumSize(CGSize(width: 120, height: 120))
        SVProgressHUD.setForegroundColor(window?.tintColor ?? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setMinimumDismissTimeInterval(3)
        SVProgressHUD.setImageViewSize(CGSize(width: 44, height: 44))
    }
}

