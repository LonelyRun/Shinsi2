import Foundation
import RealmSwift
import Alamofire
import Kingfisher
import Tiercel
import Kanna

class DownloadManager: NSObject {
    static let shared = DownloadManager()
    var queues: [OperationQueue] = []
    var books: [String: Doujinshi] = [:]
    
    var imgDownloaders = appDelegate.imgDownloaders
    let sessionManager: SessionManager = appDelegate.sessionManager

    func download(doujinshi: Doujinshi) {
        guard let gdata = doujinshi.gdata, doujinshi.pages.count != 0 else {return}
        let folderName = gdata.gid
        let path = documentURL.appendingPathComponent(folderName).path
        
        books[gdata.gid] = doujinshi
        
        let downloadCache = Cache.init(gdata.gid, downloadPath: path, downloadTmpPath: path, downloadFilePath: path)
        var configuration = SessionConfiguration()
        configuration.allowsCellularAccess = true
        configuration.maxConcurrentTasksLimit = 3
        let manager = SessionManager.init(gdata.gid, configuration: configuration, cache: downloadCache)
        manager.progress(handler: { (manager) in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "downloadProgress"),
                                            object: [doujinshi.coverUrl, CGFloat(manager.succeededTasks.count) / CGFloat(doujinshi.gdata!.filecount)])
        }).success(onMainQueue: true) { [weak self] (manager) in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "downloadProgress"),
                                            object: [doujinshi.coverUrl, CGFloat(1.0)])
            RealmManager.shared.saveDownloadedDoujinshi(book: doujinshi)
            
            if ((self?.imgDownloaders.count)!) > 0 {
                self?.imgDownloaders.removeFirst()
            }
            self?.books.removeValue(forKey: gdata.gid)
        }
        manager.totalSuspend()
        imgDownloaders.append(manager)
        imgDownloaders.first?.totalStart()
        
        for (i, p) in doujinshi.pages.enumerated() {
            if i == 0 {
                doujinshi.webCoverUrl = doujinshi.coverUrl
            }
            downloadFuntion(page:p, url: p.url, folderPath: path, pageNumber: i, downloader: manager)
        }
        
    }
    
    func cancelAllDownload() {
        for downloader in imgDownloaders {
            downloader.totalRemove()
        }
        sessionManager.totalRemove()
        books.removeAll()
    }

    func deleteDownloaded(doujinshi: Doujinshi) {
        try? FileManager.default.removeItem(at: documentURL.appendingPathComponent(doujinshi.gdata!.gid))
        RealmManager.shared.deleteDoujinshi(book: doujinshi)
    }

    func downloadFuntion(page : Page, url: String, folderPath: String, pageNumber: Int, downloader : SessionManager) {
        RequestManager.shared.downloadPageImageUrl(url: url) { (imageUrl) in
            if let imgUrl = imageUrl {
                downloader.download(imgUrl)?.success(handler: { (task) in
                    page.webUrl = imgUrl
                    page.url = task.filePath
                    if let image = UIImage(contentsOfFile: task.filePath) {
                        ImageCache.default.store(image, forKey: imgUrl)
                    }
                })
            }
        }
    }

}
