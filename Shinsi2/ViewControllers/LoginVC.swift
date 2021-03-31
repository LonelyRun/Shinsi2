import UIKit
import SVProgressHUD

class LoginVC: UIViewController {
    @IBOutlet var userNameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var exkeyField: UITextField!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet weak var webLoginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "title_icon"))
        userNameField.isHidden = true
        passwordField.isHidden = true
        loginButton.isHidden = true
        webLoginButton.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if checkCookie() {
            copyCookiesForEx(overwrite: false) //Copy if needed
            pustToList()
        } else {
            userNameField.isHidden = false
            passwordField.isHidden = false
            loginButton.isHidden = false
            webLoginButton.isHidden = false
        }
    }
    
    @IBAction func login(sender: AnyObject) {
        if let exkey = exkeyField.text , !exkey.isEmpty {
            exkeyLogin(exkey)
            return
        }
        guard let name = userNameField.text , let pw = passwordField.text else { return }
        SVProgressHUD.show()
        RequestManager.shared.login(username: name, password: pw) { response in
            switch response.result {
            case.success(_):
            if self.checkCookie() {
                SVProgressHUD.dismiss()
                self.copyCookiesForEx()
                self.pustToList()
            } else {
                SVProgressHUD.showError(withStatus: "Login failed")
                SVProgressHUD.dismiss(withDelay: 3)
            }
            case.failure(_):
                SVProgressHUD.showError(withStatus: "Login failed")
                SVProgressHUD.dismiss(withDelay: 3)
            }
        }
    }
    
    func exkeyLogin(_ exkey: String) {
        self.manuallyAddCookie(exKey: exkey)
        if self.checkCookie() {
            SVProgressHUD.dismiss()
            self.pustToList()
        } else {
            SVProgressHUD.showError(withStatus: "Login failed")
            SVProgressHUD.dismiss(withDelay: 3)
        }
    }
    
    @IBAction func webLoginButtonDidClick(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "WebVC") as! WebVC
        vc.url = Defaults.URL.login
        let nvc = UINavigationController(rootViewController: vc)
        navigationController?.present(nvc, animated: true, completion: nil)
    }
    
    func pustToList() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "ListVC") as! ListVC
        navigationController?.setViewControllers([vc], animated: false)
    }

    func checkCookie() -> Bool {
        if let cookies = HTTPCookieStorage.shared.cookies(for: Defaults.URL.eHentai) {
            return cookies.filter({$0.name == "ipb_pass_hash"}).count > 0
        }
        return false
    }

    func copyCookiesForEx(overwrite: Bool = true) {
        let exCookies = HTTPCookieStorage.shared.cookies(for: Defaults.URL.exHentai) ?? []
        guard overwrite || exCookies.count == 0 else {return}
        let eCookies = HTTPCookieStorage.shared.cookies(for: Defaults.URL.eHentai) ?? []
        eCookies.forEach{
            if var properties = $0.properties {
                properties[HTTPCookiePropertyKey.domain] = ".exhentai.org"
                if let newCookie = HTTPCookie(properties: properties) {
                    HTTPCookieStorage.shared.setCookie(newCookie)
                }
            }
        }
    }
    
    func manuallyAddCookie(exKey: String) {
        let exKeySplitted = exKey.components(separatedBy: "x")
        guard exKeySplitted.count == 2 else {
            return
        }
        
        let memberPart = exKeySplitted[0]
        let memberIdStartIndex = memberPart.index(memberPart.startIndex, offsetBy: 32)
        let memberIdCookie = createCookie(name: "ipb_member_id", value: String(memberPart[memberIdStartIndex...]))
        let passHashCookie = createCookie(name: "ipb_pass_hash", value: String(memberPart.prefix(32)))
        let igneous = createCookie(name: "igneous", value: exKeySplitted[1])
        
        let cookieList = [memberIdCookie, passHashCookie, igneous]
        
        for theCookie in cookieList {
            HTTPCookieStorage.shared.setCookie(theCookie)
            guard var properties = theCookie.properties else {
                continue
            }
            
            properties[.domain] = ".e-hentai.org" // 將同樣的Cookie也添加到表站
            if let newCookie = HTTPCookie(properties: properties) {
                HTTPCookieStorage.shared.setCookie(newCookie)
            }
        }
    }
    
    func createCookie(name: String, value: String) -> HTTPCookie {
        return HTTPCookie(properties: [.domain: ".exhentai.org",
        HTTPCookiePropertyKey.name: name,
        HTTPCookiePropertyKey.value: value,
        HTTPCookiePropertyKey.path: "/",
        HTTPCookiePropertyKey.expires: Date(timeInterval: TimeInterval(Int.max), since: Date())])!
    }
}
