import UIKit
import AloeStackView
import Kingfisher
import SVProgressHUD
import Hero
import WebKit

extension Notification.Name {
    static let settingChanged = Notification.Name("SS_SETTING_CHANGED")
}

class SettingVC: BaseViewController {
    
    lazy var stackView = AloeStackView().then {[unowned self] in
        $0.frame = self.view.bounds
        $0.hidesSeparatorsByDefault = true
        $0.separatorInset = .zero
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.barTintColor = UIColor(white: 0, alpha: 0.5)
        
        view.addSubview(stackView)

        
        //Host
        addTitle("Host")
        let hostStackView = UIStackView()
        hostStackView.distribution = .fillEqually
        hostStackView.spacing = 4
        
        let hostSeg = UISegmentedControl(items: ["E-Hentai", "EX-Hentai"])
        hostSeg.selectedSegmentIndex = Defaults.URL.host == kHostEHentai ? 0 : 1
        hostSeg.addTarget(self, action: #selector(hostSegmentedControlVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(hostSeg)
        
        //Search Filter
        addTitle("Search Filter")
        
        let categoryStackViews: [UIStackView] = [UIStackView(), UIStackView(), UIStackView(), UIStackView(), UIStackView()]
        categoryStackViews.forEach({
            $0.distribution = .fillEqually
            $0.spacing = 4
        })
        for (i, c) in Defaults.Search.categories.enumerated() {
            let b = RadioButton(type: .custom)
            b.tag = i
            b.setTitle(c, for: .normal)
            b.isSelected = UserDefaults.standard.bool(forKey: Defaults.Search.categories[b.tag])
            b.addTarget(self, action: #selector(categoryButtonDidClick(button:)), for: .touchUpInside)
            categoryStackViews[Int(i/2)].addArrangedSubview(b)
        }
        categoryStackViews.forEach({
            stackView.addRow($0)
            if $0 == categoryStackViews.first {
                stackView.setInset(forRow: $0, inset: UIEdgeInsets(top: 12, left: 12, bottom: 2, right: 12))
            } else if $0 == categoryStackViews.last {
                stackView.setInset(forRow: $0, inset: UIEdgeInsets(top: 2, left: 12, bottom: 12, right: 12))
            } else {
                stackView.setInset(forRow: $0, inset: UIEdgeInsets(top: 2, left: 12, bottom: 2, right: 12))
            }
        })
        
        // Settings
        addTitle("My Settings")
        
        let ehSetting = createTextLable("E-Hentai settings")
        ehSetting.isUserInteractionEnabled = true
        stackView.addRow(ehSetting)
        stackView.setTapHandler(forRow: ehSetting) { [weak self] _ in
            self?.presentWebViewController(url: Defaults.URL.configEH)
        }
        
        let exSetting = createTextLable("EX-Hentai settings")
        exSetting.isUserInteractionEnabled = true
        stackView.addRow(exSetting)
        stackView.setTapHandler(forRow: exSetting) { [weak self] _ in
            self?.presentWebViewController(url: Defaults.URL.configEX)
        }
        
        //UI
        addTitle("List")

        stackView.addRow(createStackView([createSubTitleLabel("Hide Title"), UISwitch().then{[unowned self] in
            $0.isOn = Defaults.List.isHideTitle
            $0.addTarget(self, action: #selector(listTitleSwitchVauleChanged(sender:)), for: .valueChanged)
        }]))
        
        
        stackView.addRow(createStackView([createSubTitleLabel("Hide Tag"), UISwitch().then {[unowned self] in
            $0.isOn = Defaults.List.isHideTag
            $0.addTarget(self, action: #selector(listTagSwitchVauleChanged(sender:)), for: .valueChanged)
        }]))
        
        
        stackView.addRow(createStackView([createSubTitleLabel("Show Favorites List"), UISwitch().then {[unowned self] in
            $0.isOn = Defaults.List.isShowFavoriteList
            $0.addTarget(self, action: #selector(listFavoriteSwitchVauleChanged(sender:)), for: .valueChanged)
        }]))
        
        
        addSubTitle("Minimum Rating")
        stackView.addRow(UISegmentedControl(items: ["2", "3", "4", "5", "ALL"]).then {[unowned self] in
            if let minimumRating = Defaults.List.minimumRating {
                $0.selectedSegmentIndex = (["2", "3", "4", "5"] as NSArray).index(of: minimumRating)
            } else {
                $0.selectedSegmentIndex = 4
            }
            $0.addTarget(self, action: #selector(minimunRatingSegmentedControlValueChanged(sender:)), for: .valueChanged)
        })

        
        //Gallery
        addTitle("Gallery")
        
        stackView.addRow(createStackView([createSubTitleLabel("Show Favorites List"), UISwitch().then {[unowned self] in
            $0.isOn = Defaults.Gallery.isShowFavoriteList
            $0.addTarget(self, action: #selector(galleryFavoriteSwitchVauleChanged(sender:)), for: .valueChanged)
        }]))
        
        stackView.addRow(createStackView([createSubTitleLabel("Continue Reading"), UISwitch().then {[unowned self] in
            $0.isOn = Defaults.Gallery.isAutomaticallyScrollToHistory
            $0.addTarget(self, action: #selector(galleryAutoScrollToHistorySwitchVauleChanged(sender:)), for: .valueChanged)
        }]))
        
        stackView.addRow(createStackView([createSubTitleLabel("Show Quick Scroll"), UISwitch().then {[unowned self] in
            $0.isOn = Defaults.Gallery.isShowQuickScroll
            $0.addTarget(self, action: #selector(galleryQuickScrollSwitchVauleChanged(sender:)), for: .valueChanged)
        }]))
        
        //Viewer
        addTitle("Viewer")
        addSubTitle("Scroll Direction")
        
        stackView.addRow(UISegmentedControl(items: ["Horizontal", "Vertical"]).then {[unowned self] in
            $0.selectedSegmentIndex = Defaults.Viewer.mode == .horizontal ? 0 : 1
            $0.addTarget(self, action: #selector(viewerModeSegmentedControlValueChanged(sender:)), for: .valueChanged)
        })
        
        stackView.addRow(UISegmentedControl(items: ["Left to Right", "Right to Left"]).then {[unowned self] in
            $0.selectedSegmentIndex = Defaults.Viewer.readDirection == .L2R ? 0 : 1
            $0.addTarget(self, action: #selector(viewerReadDirectionSegmentedControlValueChanged(sender:)), for: .valueChanged)
        })
        
        stackView.addRow(createStackView([createSubTitleLabel("DoublePage"), UISwitch().then {[unowned self] in
            $0.isOn = Defaults.Viewer.pageType
            $0.addTarget(self, action: #selector(viewerPageTypeValueChanged(sender:)), for: .valueChanged)
        }]))
        
        stackView.addRow(createStackView([createSubTitleLabel("Show PageSkip"), UISwitch().then {[unowned self] in
            $0.isOn = !Defaults.List.isHidePageSkip
            $0.addTarget(self, action: #selector(listPageSkipSwitchVauleChanged), for: .valueChanged)
        }]))
        
        stackView.addRow(createStackView([createSubTitleLabel("Tap To Scroll"), UISwitch().then {[unowned self] in
            $0.isOn = Defaults.Viewer.tapToScroll
            $0.addTarget(self, action: #selector(viewerTapToScrollValueChanged), for: .valueChanged)
        }]))
        
        stackView.addRow(createStackView([createSubTitleLabel("Show AuthorList"), UISwitch().then {[unowned self] in
            $0.isOn = Defaults.List.isShowAuthorList
            $0.addTarget(self, action: #selector(listAuthorListSwitchVauleChanged), for: .valueChanged)
        }]))
        
        addTitle("Download")
        stackView.addRow(createStackView([createSubTitleLabel("Download Delay"), UITextField().then {[unowned self] in
            $0.text = String.init(format: "%.2lf", Defaults.Download.delay)
            $0.keyboardType = .decimalPad
            $0.textAlignment = .right
            $0.addTarget(self, action: #selector(DownloadDelayVauleChanged), for: .editingDidEnd)
        }]))
        stackView.addRow(createStackView([createSubTitleLabel("Download Tasks Number"), UITextField().then {[unowned self] in
            $0.text = String.init(format: "%ld", Defaults.Download.tasks)
            $0.keyboardType = .numberPad
            $0.textAlignment = .right
            $0.addTarget(self, action: #selector(DownloadTasksVauleChanged), for: .editingDidEnd)
        }]))
        //Cache+
        addTitle("Cache")
        
        
        let clearHistory = createSubTitleLabel("Clear Search History")
        clearHistory.isUserInteractionEnabled = true
        stackView.addRow(clearHistory)
        stackView.setTapHandler(forRow: clearHistory) { _ in
            RealmManager.shared.deleteAllSearchHistory()
            SVProgressHUD.showSuccess(withStatus: nil)
        }
        
        
        let cacheSizeLable = createSubTitleLabel("size: counting...")
        stackView.addRow(cacheSizeLable)
        DispatchQueue.global(qos: .userInteractive).async {
            ImageCache.default.calculateDiskStorageSize { (result) in
                switch result {
                case .success(let value):
                    let cacheSize = Double(value) / 1024 / 1024
                    DispatchQueue.main.async { [weak self, weak cacheSizeLable] in
                        guard let self = self, let cacheSizeLable = cacheSizeLable else {return}
                        cacheSizeLable.text = String(format: "size: %.1fmb", cacheSize)
                        let clear = self.createTextLable("Delete All Cache")
                        clear.heightAnchor.constraint(equalToConstant: 50).isActive = true
                        clear.textAlignment = .right
                        clear.textColor = kMainColor
                        clear.isUserInteractionEnabled = true
                        self.stackView.insertRow(clear, after: cacheSizeLable)
                        self.stackView.setTapHandler(forRow: clear) { _ in
                            SVProgressHUD.show()
                            ImageCache.default.clearCache {
                                SVProgressHUD.showSuccess(withStatus: "Deleted")
                            }
                        }
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
        
        //Info
        addWhiteSpace(height: 60)
        let version = addSubTitle("version: \(Defaults.App.version)")
        version.textAlignment = .right
        
        //Logout
        let logout = createTextLable("Logout")
        logout.textAlignment = .center
        logout.backgroundColor = kMainColor
        logout.textColor = .white 
        logout.layer.cornerRadius = 4
        logout.clipsToBounds = true
        logout.heightAnchor.constraint(equalToConstant: 50).isActive = true
        logout.isUserInteractionEnabled = true
        stackView.addRow(logout)
        stackView.setTapHandler(forRow: logout) { [weak self] _ in
            guard let parent = self?.navigationController?.presentingViewController as? UINavigationController else {return}
            HTTPCookieStorage.shared.cookies?.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
            let vc = self?.storyboard?.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
            parent.dismiss(animated: true, completion: {
                parent.setViewControllers([vc], animated: false)
            })
            let dataStore = WKWebsiteDataStore.default()
            dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { (records) in
                for record in records {
                    dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: [record], completionHandler: {})
                }
            }
        }
    }

    @objc func categoryButtonDidClick(button: RadioButton) {
        button.isSelected.toggle()
        let key = Defaults.Search.categories[button.tag]
        UserDefaults.standard.set(button.isSelected, forKey: key)
    }
    
    @objc func hostSegmentedControlVauleChanged(sender: UISegmentedControl) {
        Defaults.URL.host = sender.selectedSegmentIndex == 0 ? kHostEHentai : kHostExHentai
    }
    
    @objc func listTagSwitchVauleChanged(sender: UISwitch) {
        Defaults.List.isHideTag = sender.isOn
        NotificationCenter.default.post(name: .settingChanged, object: nil)
    }
    
    @objc func listTitleSwitchVauleChanged(sender: UISwitch) {
        Defaults.List.isHideTitle = sender.isOn
        NotificationCenter.default.post(name: .settingChanged, object: nil)
    }
    
    @objc func listFavoriteSwitchVauleChanged(sender: UISwitch) {
        Defaults.List.isShowFavoriteList = sender.isOn
    }
    
    @objc func listAuthorListSwitchVauleChanged(sender: UISwitch) {
        Defaults.List.isShowAuthorList = sender.isOn
        NotificationCenter.default.post(name: .settingChanged, object: nil)
    }
    
    @objc func listPageSkipSwitchVauleChanged(sender: UISwitch) {
        Defaults.List.isHidePageSkip = !sender.isOn
        NotificationCenter.default.post(name: .settingChanged, object: nil)
    }
    
    @objc func DownloadDelayVauleChanged(sender: UITextField) {
        if let text = sender.text {
            Defaults.Download.delay = Double(text)!
        }
    }
    
    @objc func DownloadTasksVauleChanged(sender: UITextField) {
        if let text = sender.text {
            Defaults.Download.tasks = Int(text)!
        }
    }
    
    @objc func galleryQuickScrollSwitchVauleChanged(sender: UISwitch) {
        Defaults.Gallery.isShowQuickScroll = sender.isOn
    }
    
    @objc func galleryFavoriteSwitchVauleChanged(sender: UISwitch) {
        Defaults.Gallery.isShowFavoriteList = sender.isOn
    }
    
    @objc func galleryAutoScrollToHistorySwitchVauleChanged(sender: UISwitch) {
        Defaults.Gallery.isAutomaticallyScrollToHistory = sender.isOn
    }
    
    @objc func minimunRatingSegmentedControlValueChanged(sender: UISegmentedControl) {
        if (sender.selectedSegmentIndex == 4) {
            Defaults.List.minimumRating = nil
        } else {
            Defaults.List.minimumRating = ["2", "3", "4", "5"][sender.selectedSegmentIndex]
        }
    }
    
    @objc func viewerModeSegmentedControlValueChanged(sender: UISegmentedControl) {
        Defaults.Viewer.mode = sender.selectedSegmentIndex == 0 ? .horizontal : .vertical
    }
    
    @objc func viewerReadDirectionSegmentedControlValueChanged(sender:UISegmentedControl){
        Defaults.Viewer.readDirection = sender.selectedSegmentIndex == 0 ? .L2R : .R2L
    }
    
    
    @objc func viewerTapToScrollValueChanged(sender: UISwitch) {
        Defaults.Viewer.tapToScroll = sender.isOn
    }
    
    @objc func viewerPageTypeValueChanged(sender: UISwitch) {
        Defaults.Viewer.pageType = sender.isOn
    }
    
    func presentWebViewController(url: URL) {
        guard let parent = navigationController?.presentingViewController else {return}
        let vc = storyboard?.instantiateViewController(withIdentifier: "WebVC") as! WebVC
        vc.url = url
        let nvc = UINavigationController(rootViewController: vc)
        parent.dismiss(animated: true, completion: {
            parent.present(nvc, animated: true, completion: nil)
        })
    }
    
    func createTitleLable(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = UIColor.darkGray
        return label
    }
    
    @discardableResult func addTitle(_ text: String, showSeperator: Bool = true) -> UILabel {
        let view = createTitleLable(text)
        stackView.addRow(view)
        if showSeperator {
            stackView.showSeparator(forRow: view)
        }
        return view
    }
    
    func createTextLable(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        return label
    }
    
    func createSubTitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor.init(white: 0.5, alpha: 1)
        return label
    }
    
    func createTextField(_ text: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = text
        return textField
    }
    
    func StringToFloat(str:String)->(CGFloat){
        let string = str
        var cgFloat:CGFloat = 0.0
        if let doubleValue = Double(string) {
            cgFloat = CGFloat(doubleValue)
        }
        return cgFloat
    }

    @discardableResult func addSubTitle(_ text: String) -> UILabel {
        let label = createSubTitleLabel(text)
        stackView.addRow(label)
        stackView.setInset(forRow: label, inset: UIEdgeInsets(top: 12, left: 15, bottom: 0, right: 15))
        return label
    }
    
    func createStackView(_ views: [UIView], axis: NSLayoutConstraint.Axis = .horizontal, distribution: UIStackView.Distribution = .fill) -> UIStackView {
        let s = UIStackView(arrangedSubviews: views)
        s.axis = axis
        s.distribution = distribution
        return s
    }
    
    func addWhiteSpace(height: CGFloat) {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        stackView.addRow(view)
    }
}

class RadioButton: UIButton {

    override var isSelected: Bool { didSet { setNeedsDisplay() } }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let p = UIBezierPath(roundedRect: rect, cornerRadius: 4)
        let color: UIColor = isSelected ?  tintColor : UIColor(white: 0.8, alpha: 1)
        color.set()
        p.fill()
    }

}
