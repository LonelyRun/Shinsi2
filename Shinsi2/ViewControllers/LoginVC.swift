import UIKit
import SVProgressHUD

class LoginVC: UIViewController {

    @IBOutlet var userNameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "title_icon"))
        userNameField.isHidden = true
        passwordField.isHidden = true
        loginButton.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if checkCookie() {
            pustToList()
        } else {
            userNameField.isHidden = false
            passwordField.isHidden = false
            loginButton.isHidden = false
        }
    }
    
    @IBAction func login(sender: AnyObject) {
        guard let name = userNameField.text , let pw = passwordField.text else { return }
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

    func pustToList() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "ListVC") as! ListVC
        navigationController?.setViewControllers([vc], animated: false)
    }

    func checkCookie() -> Bool {
        if let cookies = HTTPCookieStorage.shared.cookies(for: kEHentaiURL) {
            for c in cookies {
                if c.name == "ipb_pass_hash" {
                    return true
                }
            }
        }
        return false
    }

    func copyCookiesForEx() {
        if let cookies = HTTPCookieStorage.shared.cookies(for: kEHentaiURL) { 
            for c in cookies {
                if var properties = c.properties {
                    properties[HTTPCookiePropertyKey.domain] = ".exhentai.org"
                    if let newCookie = HTTPCookie(properties: properties) {
                        HTTPCookieStorage.shared.setCookie(newCookie)
                    }
                }
            }
        }
    }
}
