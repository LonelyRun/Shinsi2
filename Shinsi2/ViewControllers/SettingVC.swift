import UIKit
import AloeStackView
import SDWebImage
import SVProgressHUD
import Hero
import WebKit

extension Notification.Name {
    static let settingChanged = Notification.Name("SS_SETTING_CHANGED")
}

class SettingVC: BaseViewController {
    
    let stackView = AloeStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.barTintColor = UIColor(white: 0, alpha: 0.5)
        
        view.addSubview(stackView)
        stackView.frame = view.bounds
        stackView.hidesSeparatorsByDefault = true
        stackView.separatorInset = .zero
        stackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
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
        
        let titleLabel = createSubTitleLabel("Hide Title")
        let titleSwitch = UISwitch()
        titleSwitch.isOn = Defaults.List.isHideTitle
        titleSwitch.addTarget(self, action: #selector(listTitleSwitchVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(createStackView([titleLabel, titleSwitch]))
        
        let tagLabel = createSubTitleLabel("Hide Tag")
        let tagSwitch = UISwitch()
        tagSwitch.isOn = Defaults.List.isHideTag
        tagSwitch.addTarget(self, action: #selector(listTagSwitchVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(createStackView([tagLabel, tagSwitch]))
        
        let listFavLabel = createSubTitleLabel("Show Favorites List")
        let listFavSwitch = UISwitch()
        listFavSwitch.isOn = Defaults.List.isShowFavoriteList
        listFavSwitch.addTarget(self, action: #selector(listFavoriteSwitchVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(createStackView([listFavLabel, listFavSwitch]))
        
        //Gallery
        addTitle("Gallery")
        
        let galleryFavLabel = createSubTitleLabel("Show Favorites List")
        let galleryFavSwitch = UISwitch()
        galleryFavSwitch.isOn = Defaults.Gallery.isShowFavoriteList
        galleryFavSwitch.addTarget(self, action: #selector(galleryFavoriteSwitchVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(createStackView([galleryFavLabel, galleryFavSwitch]))
        
        let autoScrollLabel = createSubTitleLabel("Continue Reading")
        let autoScrollSwitch = UISwitch()
        autoScrollSwitch.isOn = Defaults.Gallery.isAutomaticallyScrollToHistory
        autoScrollSwitch.addTarget(self, action: #selector(galleryAutoScrollToHistorySwitchVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(createStackView([autoScrollLabel, autoScrollSwitch]))
        
        let quickScrollLabel = createSubTitleLabel("Show Quick Scroll")
        let quickScrollSwitch = UISwitch()
        quickScrollSwitch.isOn = Defaults.Gallery.isShowQuickScroll
        quickScrollSwitch.addTarget(self, action: #selector(galleryQuickScrollSwitchVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(createStackView([quickScrollLabel, quickScrollSwitch]))
        
        //Viewer
        addTitle("Viewer")
        addSubTitle("Scroll Direction")
        let viewerModeSeg = UISegmentedControl(items: ["Horizontal", "Vertical"])
        viewerModeSeg.selectedSegmentIndex = Defaults.Viewer.mode == .horizontal ? 0 : 1
        viewerModeSeg.addTarget(self, action: #selector(viewerModeSegmentedControlValueChanged(sender:)), for: .valueChanged)
        let viewerReadDirectionSeg = UISegmentedControl(items: ["Left to Right", "Right to Left"])
        viewerReadDirectionSeg.selectedSegmentIndex = Defaults.Viewer.readDirection == .L2R ? 0 : 1
        viewerReadDirectionSeg.addTarget(self, action: #selector(viewerReadDirectionSegmentedControlValueChanged(sender:)), for: .valueChanged)
        stackView.addRow(viewerModeSeg)
        stackView.addRow(viewerReadDirectionSeg)
        
        let readPageLabel = createSubTitleLabel("DoublePage")
        let viewerReadPageSeg = UISwitch()
        viewerReadPageSeg.isOn = Defaults.Viewer.pageType
        viewerReadPageSeg.addTarget(self, action: #selector(viewerPageTypeValueChanged(sender:)), for: .valueChanged)
        stackView.addRow(createStackView([readPageLabel, viewerReadPageSeg]))
        
        let showPageSkipLabel = createSubTitleLabel("Show PageSkip")
        let pageSkipSwitch = UISwitch()
        pageSkipSwitch.isOn = !Defaults.List.isHidePageSkip
        pageSkipSwitch.addTarget(self, action: #selector(listPageSkipSwitchVauleChanged), for: .valueChanged)
        stackView.addRow(createStackView([showPageSkipLabel, pageSkipSwitch]))
        
        let tapToScrollLabel = createSubTitleLabel("Tap To Scroll")
        let tapToScrollSwitch = UISwitch()
        tapToScrollSwitch.isOn = Defaults.Viewer.tapToScroll
        tapToScrollSwitch.addTarget(self, action: #selector(viewerTapToScrollValueChanged), for: .valueChanged)
        stackView.addRow(createStackView([tapToScrollLabel, tapToScrollSwitch]))
        
        let showAuthorListLabel = createSubTitleLabel("Show AuthorList")
        let authorListSwitch = UISwitch()
        authorListSwitch.isOn = Defaults.List.isShowAuthorList
        authorListSwitch.addTarget(self, action: #selector(listAuthorListSwitchVauleChanged), for: .valueChanged)
        stackView.addRow(createStackView([showAuthorListLabel, authorListSwitch]))
        
        //Cache+
        addTitle("Cache")
        let cacheSizeLable = createSubTitleLabel("size: counting...")
        stackView.addRow(cacheSizeLable)
        DispatchQueue.global(qos: .userInteractive).async {
            let cacheSize = Double(SDImageCache.shared().getSize()) / 1024 / 1024
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
                    SDImageCache.shared().clearDisk(onCompletion: {
                        SVProgressHUD.showSuccess(withStatus: "Deleted")
                    })
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
    
    @objc func galleryQuickScrollSwitchVauleChanged(sender: UISwitch) {
        Defaults.Gallery.isShowQuickScroll = sender.isOn
    }
    
    @objc func galleryFavoriteSwitchVauleChanged(sender: UISwitch) {
        Defaults.Gallery.isShowFavoriteList = sender.isOn
    }
    
    @objc func galleryAutoScrollToHistorySwitchVauleChanged(sender: UISwitch) {
        Defaults.Gallery.isAutomaticallyScrollToHistory = sender.isOn
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
