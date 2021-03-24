import Foundation
import HandyJSON
import RealmSwift

class BrowsingHistory: Object {
    @objc dynamic var doujinshi: Doujinshi?
    @objc dynamic var currentPage: Int = 0
    @objc dynamic var id: Int = 999999999
    @objc dynamic var createdAt: Date = Date()
    @objc dynamic var updatedAt: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class Doujinshi: Object, HandyJSON {
    @objc dynamic var coverUrl = ""
    @objc dynamic var title = ""
    @objc dynamic var url = ""
    @objc dynamic var pageCount = ""


    let pages = List<Page>()
    @objc dynamic var gdata: GData?
    @objc dynamic var isFavorite = false
    @objc dynamic var isDownloaded = false 
    @objc dynamic var date = Date()
    
    var perPageCount: Int?
    
    //Won't store
    var comments: [Comment] = []
    
    //Computed property
    var id: Int { 
        guard let u = URL(string: url), u.pathComponents.indices.contains(2), let d = Int(u.pathComponents[2]) else {return 999999999}
        return d
    }
    var token: String {
        guard let u = URL(string: url), u.pathComponents.indices.contains(3) else {return "invalid_token"}
        return u.pathComponents[3]
    }
    var isIdTokenValide: Bool {
        return id != 999999999 && token != "invalid_token"
    }
    var canDownload: Bool {
        if isDownloaded {
            return false
        } else if let gdata = gdata, gdata.filecount == pages.count {
            return true
        }
        return false
    }
    
    
    var author: String {
        do {
            var regex = try NSRegularExpression(pattern: "\\[.+?\\]", options: [])
            guard let outRange = regex.matches(in: title, options: [], range: NSMakeRange(0, title.count)).first?.range else {
                return ""
            }
            let string = (title as NSString).substring(with: NSMakeRange(outRange.location + 1, outRange.length - 2))
            regex = try NSRegularExpression(pattern: "\\(.+?\\)", options: [])
            guard let innerRange = regex.matches(in: string, options: [], range: NSMakeRange(0, string.count)).first?.range else {
                return string
            }
            return (string as NSString).substring(with: NSMakeRange(innerRange.location + 1, innerRange.length - 2))
        }
        catch {
            return ""
        }
    }
    
    override static func ignoredProperties() -> [String] {
        return ["comments", "commentScrollPosition", "perPageCount"]
    }
    
    override required init() {}
}

class Page: Object {
    @objc dynamic var thumbUrl = ""
    @objc dynamic var url = ""
    var photo: SSPhoto!
    var localUrl: URL {
        return documentURL.appendingPathComponent(thumbUrl)
    }
    var localImage: UIImage? {
        return UIImage(contentsOfFile: localUrl.path)
    }
    static func blankPage() -> Page {
        let p = Page()
        p.photo = SSPhoto(URL: "")
        return p
    }
}

class Author: Object, HandyJSON {
    @objc dynamic var author: String = ""
    var covers = List<String>()
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            self.covers <-- TransformOf<List<String>, [String]>(fromJSON: { (jsonArr) -> List<String>? in
                let list = List<String>()
                if let jsonArr = jsonArr, jsonArr.count > 0 {
                    for item in jsonArr {
                        list.append(item)
                    }
                }
                return list
            }, toJSON: { (list) -> [String]? in
                var result: [String] = []
                list?.forEach({ (covers) in
                    result.append(covers)
                })
                return result
            })
    }
    
    override required init() {}
}

class GData: Object {
    @objc dynamic var gid = ""
    @objc dynamic var filecount = 0
    @objc dynamic var rating: Float = 0.0
    @objc dynamic var title = ""
    @objc dynamic var title_jpn = ""
    func getTitle() -> String {
        return title_jpn.isEmpty ? title : title_jpn
    }
    @objc dynamic var coverUrl = ""
    let tags = List<Tag>()
    lazy var gTag: GTag = {
        var g = GTag()
        let keys = g.allProperties().keys
        tags.forEach {
            if $0.name.contains(":"), let key = $0.name.components(separatedBy: ":").first, keys.contains(key) {
                g[key].append($0.name.replacingOccurrences(of: "\(key):", with: ""))
            } else {
                g["misc"].append($0.name)
            }
        }
        return g
    }()
    
    override static func ignoredProperties() -> [String] {
        return ["gTag"]
    }
}

class Tag: Object {
    @objc dynamic var name = ""
}

class SearchHistory: Object {
    @objc dynamic var text: String = ""
    @objc dynamic var date: Date = Date()
}



struct Comment {
    var author: String
    var date: Date
    var text: String
    var htmlAttributedText: NSAttributedString?
    init(author: String, date: Date, text: String) {
        self.author = author
        self.date = date
        self.text = text
        self.htmlAttributedText = text.htmlAttribute
    }
}

struct GTag: PropertyLoopable {
    var language: [String] = []
    var artist: [String] = []
    var group: [String] = []
    var parody: [String] = []
    var character: [String] = []
    var male: [String] = []
    var female: [String] = []
    var misc: [String] = []
    
    subscript(key: String) -> [String] {
        get {
            switch key {
            case "language":
                return language
            case "artist":
                return artist
            case "group":
                return group
            case "parody":
                return parody
            case "character":
                return character
            case "male":
                return male
            case "female":
                return female
            case "misc":
                return misc
            default:
                return []
            }
        }
        set(newValue) {
            switch key {
            case "language":
                language = newValue
            case "artist":
                artist = newValue
            case "group":
                group = newValue
            case "parody":
                parody = newValue
            case "character":
                character = newValue
            case "male":
                male = newValue
            case "female":
                female = newValue
            case "misc":
                misc = newValue
            default:
                break
            }
        }
    }
}
