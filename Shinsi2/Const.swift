import UIKit

//URL
public let kEHentaiURL = URL(string: "https://e-hentai.org")!
public let kEXHentaiURL = URL(string: "https://exhentai.org")!
public let kHostExHentai = "https://exhentai.org"
public let kHostEHentai = "https://e-hentai.org"

//Shortcut
public let documentURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
public let paperRatio = CGFloat(sqrt(2)) //A4 ratio
public let isSizeClassRegular = UIApplication.shared.keyWindow?.rootViewController?.traitCollection.horizontalSizeClass ?? .compact == .regular

//User default
public let kUDHost = "kUDHost"

public let kUDListCellWidth = "kUDListCellWidth"
public let kUDListLastSearchKeyword = "kUDListLastSearchKeyword"
public let kUDListHideTag = "kUDListHideTag"
public let kUDListHideTitle = "kUDListHideTitle"
public let kUDListFavoriteTitles = "kUDListFavoriteTitles"
public let kUDListFavoriteList = "kUDListFavoriteList"

public let kUDGalleryCellWidth = "kUDGalleryCellWidth"
public let kUDGalleryQuickScroll = "kUDGalleryQuickScroll"
public let kUDGalleryBlankPage = "kUDGalleryBlankPage"
public let kUDGalleryFavoriteList = "kUDGalleryFavoriteList"

public let kUDViewerMode = "kUDViewerMode"

//Color
public let kMainColor = UIApplication.shared.keyWindow?.tintColor ?? #colorLiteral(red: 0.8459790349, green: 0.2873021364, blue: 0.2579272389, alpha: 1)

class Defaults {
    class App {
        static var version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
    class URL {
        static var host: String {
            get {  return UserDefaults.standard.string(forKey: kUDHost) ?? kHostEHentai }
            set { UserDefaults.standard.set(newValue, forKey: kUDHost) }
        }
    }
    class Search {
        static var categories: [String] = ["doujinshi","manga","artistcg","gamecg","western","non-h","imageset","cosplay","asianporn","misc"]
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
        static var isShowFavoriteList: Bool {
            get { return UserDefaults.standard.bool(forKey: kUDListFavoriteList) }
            set { UserDefaults.standard.set(newValue, forKey: kUDListFavoriteList) }
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
            get { return UserDefaults.standard.array(forKey: kUDListFavoriteTitles) as? [String] ?? "0123456789".map{ "Favorites \($0)"}}
            set { UserDefaults.standard.set(newValue, forKey: kUDListFavoriteTitles)}
        }
    }
    class Gallery {
        static var isShowQuickScroll: Bool {
            get { return UserDefaults.standard.bool(forKey: kUDGalleryQuickScroll) }
            set { UserDefaults.standard.set(newValue, forKey: kUDGalleryQuickScroll) }
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
    }
    
}
