import UIKit

//URL
let kHostEHentai = "https://e-hentai.org"
let kHostExHentai = "https://exhentai.org"

//Shortcut
let documentURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
let paperRatio = CGFloat(sqrt(2)) //A4 ratio

let kHorizontalSizeClass = UIApplication.shared.keyWindow?.rootViewController?.traitCollection.horizontalSizeClass ?? .compact
let kVerticalSizeClass = UIApplication.shared.keyWindow?.rootViewController?.traitCollection.verticalSizeClass ?? .compact
let isSizeClassRegular = kHorizontalSizeClass == .regular && kVerticalSizeClass == .regular

//User default
let kUDHost = "kUDHost"

let kUDListCellWidth = "kUDListCellWidth"
let kUDListLastSearchKeyword = "kUDListLastSearchKeyword"
let kUDListHideTag = "kUDListHideTag"
let kUDListHideTitle = "kUDListHideTitle"
let kUDListFilterLanguage = "kUDListFilterLanguage"
let kUDListLanguage = "kUDListLanguage"
let kUDListHidePageSkip = "kUDListHidePageSkip"
let kUDShowAuthorListSkip = "kUDShowAuthorListSkip"
let kUDListFavoriteTitles = "kUDListFavoriteTitles"
let kUDListFavoriteList = "kUDListFavoriteList"
let kUDListMinimumRating = "kUDListMinimumRating"
let kUDListMinimunPages = "kUDListMinimunPages"
let kUDListMaximumPages = "kUDListMaximumPages"

let kUDGalleryCellWidth = "kUDGalleryCellWidth"
let kUDGalleryQuickScroll = "kUDGalleryQuickScroll"
let kUDGalleryBlankPage = "kUDGalleryBlankPage"
let kUDGalleryFavoriteList = "kUDGalleryFavoriteList"
let kUDGalleryAutomaticallyScrollToHistory = "kUDGalleryAutomaticallyScrollToHistory"

let kUDViewerMode = "kUDViewerMode"

let kUDViewerReadDirection = "kUDViewerReadDirection"
let kUDViewerReloadData = "kUDViewerReloadData"

let kUDViewerTapToScroll = "kUDViewerTapToScroll"

let kUDViewerPageType = "kUDViewerPageType"
let kUDDownloadDelayValue = "kUDDownloadDelayValue"
let kUDDownloadTasksValue = "kUDDownloadTasksValue"

//Color
let kMainColor = UIApplication.shared.keyWindow?.tintColor ?? #colorLiteral(red: 0.8459790349, green: 0.2873021364, blue: 0.2579272389, alpha: 1)

class Defaults {
    class App {
        static var version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
    class URL {
        static var host: String {
            get {  return UserDefaults.standard.string(forKey: kUDHost) ?? kHostEHentai }
            set { UserDefaults.standard.set(newValue, forKey: kUDHost) }
        }
        static var eHentai: Foundation.URL = Foundation.URL(string: "https://e-hentai.org")!
        static var exHentai: Foundation.URL = Foundation.URL(string: "https://exhentai.org")!
        static var login: Foundation.URL = Foundation.URL(string: "https://forums.e-hentai.org/index.php?act=Login")!
        static var configEH: Foundation.URL = Foundation.URL(string: kHostEHentai + "/uconfig.php")!
        static var configEX: Foundation.URL = Foundation.URL(string: kHostExHentai + "/uconfig.php")!
    }
    class Search {
        static var categories: [String] = ["doujinshi", "manga", "artistcg", "gamecg", "western", "non-h", "imageset", "cosplay", "asianporn", "misc"]
    }
    class List {
        static var isHideTitle: Bool {
            get { return UserDefaults.standard.bool(forKey: kUDListHideTitle) }
            set { UserDefaults.standard.set(newValue, forKey: kUDListHideTitle) }
        }
        static var isHideTag: Bool {
            get { return UserDefaults.standard.bool(forKey: kUDListHideTag) }
            set { UserDefaults.standard.set(newValue, forKey: kUDListHideTag) }
        }
//        static var isHidePageSkip: Bool {
//            get { return UserDefaults.standard.bool(forKey: kUDListHidePageSkip) }
//            set { UserDefaults.standard.set(newValue, forKey: kUDListHidePageSkip) }
//        }
        static var isFilterLanguage: Bool {
            get { return UserDefaults.standard.bool(forKey: kUDListFilterLanguage) }
            set { UserDefaults.standard.set(newValue, forKey: kUDListFilterLanguage) }
        }
        static var listLanguage: String {
            get { return UserDefaults.standard.string(forKey: kUDListLanguage) ?? ""}
            set { UserDefaults.standard.set(newValue, forKey: kUDListLanguage)}
        }
        static var isShowAuthorList: Bool {
            get { return UserDefaults.standard.bool(forKey: kUDShowAuthorListSkip) }
            set { UserDefaults.standard.set(newValue, forKey: kUDShowAuthorListSkip) }
        }
        static var isShowFavoriteList: Bool {
            get { return UserDefaults.standard.bool(forKey: kUDListFavoriteList) }
            set { UserDefaults.standard.set(newValue, forKey: kUDListFavoriteList) }
        }
        static var minimumRating: String? {
            get { return UserDefaults.standard.string(forKey: kUDListMinimumRating)}
            set { UserDefaults.standard.set(newValue, forKey: kUDListMinimumRating)}
        }
        static var minimumPages: String {
            get { return UserDefaults.standard.string(forKey: kUDListMinimunPages) ?? ""}
            set { UserDefaults.standard.set(newValue, forKey: kUDListMinimunPages)}
        }
        static var maximumPages: String {
            get { return UserDefaults.standard.string(forKey: kUDListMaximumPages) ?? ""}
            set { UserDefaults.standard.set(newValue, forKey: kUDListMaximumPages)}
        }
        static var lastSearchKeyword: String {
            get { return UserDefaults.standard.string(forKey: kUDListLastSearchKeyword) ?? "" }
            set { UserDefaults.standard.set(newValue, forKey: kUDListLastSearchKeyword) }
        }
        static var defaultCellWidth: CGFloat { return isSizeClassRegular ? CGFloat(200) : CGFloat(140)}
        static var cellWidth: CGFloat {
            get { return UserDefaults.standard.float(forKey: kUDListCellWidth) == 0 ? Defaults.List.defaultCellWidth : CGFloat(UserDefaults.standard.float(forKey: kUDListCellWidth)) }
            set { UserDefaults.standard.set(newValue, forKey: kUDListCellWidth) }
        }
        static var favoriteTitles: [String] {
            get { return UserDefaults.standard.array(forKey: kUDListFavoriteTitles) as? [String] ?? "0123456789".map { "Favorites \($0)"}}
            set { UserDefaults.standard.set(newValue, forKey: kUDListFavoriteTitles)}
        }
    }
    class Gallery {
        static var isShowQuickScroll: Bool {
            get { return UserDefaults.standard.bool(forKey: kUDGalleryQuickScroll) }
            set { UserDefaults.standard.set(newValue, forKey: kUDGalleryQuickScroll) }
        }
        static var isAutomaticallyScrollToHistory: Bool {
            get { return UserDefaults.standard.bool(forKey: kUDGalleryAutomaticallyScrollToHistory) }
            set { UserDefaults.standard.set(newValue, forKey: kUDGalleryAutomaticallyScrollToHistory) }
        }
        static var isAppendBlankPage: Bool {
            get { return UserDefaults.standard.bool(forKey: kUDGalleryBlankPage) }
            set { UserDefaults.standard.set(newValue, forKey: kUDGalleryBlankPage) }
        }
        static var isShowFavoriteList: Bool {
            get { return UserDefaults.standard.bool(forKey: kUDGalleryFavoriteList) }
            set { UserDefaults.standard.set(newValue, forKey: kUDGalleryFavoriteList) }
        }
        static var defaultCellWidth: CGFloat { return isSizeClassRegular ? CGFloat(200) : CGFloat(140)}
        static var cellWidth: CGFloat {
            get { return UserDefaults.standard.float(forKey: kUDGalleryCellWidth) == 0 ? Defaults.Gallery.defaultCellWidth : CGFloat(UserDefaults.standard.float(forKey: kUDGalleryCellWidth)) }
            set { UserDefaults.standard.set(newValue, forKey: kUDGalleryCellWidth) }
        }
    }
    class Viewer {
        static var mode: ViewerVC.ViewerMode {
            get { return ViewerVC.ViewerMode(rawValue: UserDefaults.standard.integer(forKey: kUDViewerMode))! }
            set { UserDefaults.standard.set(newValue.rawValue, forKey: kUDViewerMode) }
        }
        static var readDirection : ViewerVC.ViewerReadDirection{
            get { return ViewerVC.ViewerReadDirection(rawValue: UserDefaults.standard.integer(forKey: kUDViewerReadDirection))!}
            set {UserDefaults.standard.set(newValue.rawValue, forKey: kUDViewerReadDirection)}
        }
        static var tapToScroll : Bool {
            get { return UserDefaults.standard.bool(forKey: kUDViewerTapToScroll)}
            set { UserDefaults.standard.setValue(newValue, forKey: kUDViewerTapToScroll)}
        }
        static var pageType : Bool {
            get { return UserDefaults.standard.bool(forKey: kUDViewerPageType)}
            set { UserDefaults.standard.setValue(newValue, forKey: kUDViewerPageType)}
        }
    }
    class Download {
        static var delay : Double {
            get { guard let value = UserDefaults.standard.object(forKey: kUDDownloadDelayValue) else { return 1.0 }
                return value as! Double}
            set {UserDefaults.standard.set(newValue, forKey: kUDDownloadDelayValue) }
        }
        static var tasks : Int {
            get { guard let value = UserDefaults.standard.object(forKey: kUDDownloadTasksValue) else { return 3 }
                return value as! Int}
            set {UserDefaults.standard.set(newValue, forKey: kUDDownloadTasksValue) }
        }
    }
}
