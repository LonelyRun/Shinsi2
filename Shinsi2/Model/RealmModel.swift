import Foundation
import RealmSwift

class Doujinshi : Object {
    @objc dynamic var coverUrl = ""
    @objc dynamic var title = ""
    @objc dynamic var url = ""

    let pages = List<Page>()
    @objc dynamic var gdata : GData?
    @objc dynamic var isFavorite = false
    @objc dynamic var isDownloaded = false
    @objc dynamic var localFolderPath = ""
    @objc dynamic var date = Date()
    
    var comments: [Comment] = []
    
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
    
    override static func ignoredProperties() -> [String] {
        return ["comments"]
    }
}

class Page : Object {
    @objc dynamic var thumbUrl = ""
    @objc dynamic var url = ""
    var photo: SSPhoto!
    var localImage: UIImage? {
        return UIImage(contentsOfFile: documentURL.appendingPathComponent(thumbUrl).path)
    }
}

class GData : Object {
    @objc dynamic var gid = ""
    @objc dynamic var filecount = 0
    @objc dynamic var rating : Float = 0.0
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
        for t in self.tags {
            if t.name.contains(":") {
                for key in keys {
                    if t.name.hasPrefix("\(key):") {
                        g[key].append(t.name.replacingOccurrences(of: "\(key):", with: ""))
                        break
                    }
                }
            } else {
                g["misc"].append(t.name)
            }
        }
        return g
    }()
    
    override static func ignoredProperties() -> [String] {
        return ["gTag"]
    }
}

class Tag : Object {
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
    var textHtml: NSAttributedString?
    init(author: String, date: Date, text: String) {
        self.author = author
        self.date = date
        self.text = text
        self.textHtml = text.htmlAttribute
    }
}

struct GTag : PropertyLoopable {
    var language: [String] = []
    var artist: [String] = []
    var group: [String] = []
    var parody: [String] = []
    var character: [String] = []
    var male: [String] = []
    var female: [String] = []
    var misc: [String] = []
    
    subscript(key:String) -> [String] {
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
