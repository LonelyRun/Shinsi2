import UIKit
import SVProgressHUD

class LoginVC: UIViewController {
    @IBOutlet var userNameField: UITextField!
    @IBOutlet var passwordField: UITextField!
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
        guard let name = userNameField.text, let pw = passwordField.text else { return }
        SVProgressHUD.show()
        RequestManager.shared.login(username: name, password: pw) {
            if self.checkCookie() {
                SVProgressHUD.dismiss()
                self.copyCookiesForEx()
                self.pustToList()
            } else {
                SVProgressHUD.showError(withStatus: "Login failed")
                SVProgressHUD.dismiss(withDelay: 3)
            }
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
}
