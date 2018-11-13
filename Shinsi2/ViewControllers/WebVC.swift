import UIKit
import WebKit

class WebVC: BaseViewController {
    
    var url: URL?
    @IBOutlet weak var webView: WKWebView!
    private var backGesture: InteractiveBackGesture?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = UIColor(white: 0, alpha: 0.5)
        backGesture = InteractiveBackGesture(viewController: self, toView: webView, mode: .modal, isSimultaneously: true)
        
        //Copy cookies
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        for cookie in cookies {
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
        }
        
        if let url = url {
            webView.load(URLRequest(url: url))
        }
    }

}
