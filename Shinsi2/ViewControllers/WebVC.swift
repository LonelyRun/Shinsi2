import UIKit
import WebKit

class WebVC: UIViewController {
    
    var url: URL?
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = UIColor(white: 0, alpha: 0.5)
        
        //Copy cookies
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        cookies.forEach {
            webView.configuration.websiteDataStore.httpCookieStore.setCookie($0)
        }
        
        if let url = url {
            webView.load(URLRequest(url: url))
        }
    }
    
    @IBAction func doneButtonDidClick(sender: UIBarButtonItem) {
        //copy back
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies{ cookies in
            cookies.forEach {
                HTTPCookieStorage.shared.setCookie($0)
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
}
