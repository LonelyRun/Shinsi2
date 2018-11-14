import Foundation
import RealmSwift

class RealmManager {
    static let shared = RealmManager()
    let realm: Realm = {
        let config = Realm.Configuration( schemaVersion: 7, migrationBlock: { migration, oldSchemaVersion in
            
        })
        Realm.Configuration.defaultConfiguration = config
        return try! Realm()
    }()
    
    lazy var searchHistory: Results<SearchHistory> = {
        return self.realm.objects(SearchHistory.self).sorted(byKeyPath: "date", ascending: false)
    }()
    
    lazy var downloaded: Results<Doujinshi> = {
        return self.realm.objects(Doujinshi.self).sorted(byKeyPath: "date", ascending: false)
    }()
    
    func saveSearchHistory(text: String?) {
        guard let text = text else {return}
        guard text.replacingOccurrences(of: " ", with: "").count != 0 else {return}
        if let obj = realm.objects(SearchHistory.self).filter("text = %@", text).first {
            try! realm.write {
                obj.date = Date()
            }
        } else {
            try! realm.write {
                let h = SearchHistory()
                h.text = text
                realm.add(h)
            }
        }
    }
    
    func deleteAllSearchHistory() {
        try! realm.write {
            realm.delete(realm.objects(SearchHistory.self))
        }
    }
    
    func deleteSearchHistory(history: SearchHistory) {
        try! realm.write {
            realm.delete(history)
        }
    }
    
    func saveDownloadedDoujinshi(book:Doujinshi) {
        book.pages.removeAll()
        for i in 0..<book.gdata!.filecount {
            let p = Page()
            p.thumbUrl = String(format: book.gdata!.gid + "/%04d.jpg", i)
            book.pages.append(p)
        }
        if let first = book.pages.first {
            book.coverUrl = first.thumbUrl
        }
        book.isDownloaded = true
        book.date = Date()
        
        DispatchQueue.main.async {
            try! self.realm.write {
                self.realm.add(book)
            }
        }
    }
    
    func deleteDoujinshi(book:Doujinshi) {
        try! realm.write {
            realm.delete(book)
        }
    }
    
    func isDounjinshiDownloaded(doujinshi:Doujinshi) -> Bool {
        return downloaded.filter("gdata.gid = '\(doujinshi.gdata!.gid)'").count != 0
    }
}
