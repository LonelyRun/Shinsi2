import UIKit
import WebKit

class WebVC: BaseViewController {
    
    var url: URL?
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
