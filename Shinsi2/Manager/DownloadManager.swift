import Foundation
import RealmSwift
import Alamofire
import Kingfisher
import Tiercel

class SSOperation: Operation {
    enum State {
        case ready, executing, finished
        var keyPath: String {
            switch self {
            case .ready:
                return "isReady"
            case .executing:
                return "isExecuting"
            case .finished:
                return "isFinished"
            }
        }
    }
    var state = State.ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
    override var isReady: Bool { return super.isReady && state == .ready }
    override var isExecuting: Bool { return state == .executing }
    override var isFinished: Bool { return state == .finished }
    override var isAsynchronous: Bool { return true }
}

class PageDownloadOperation: SSOperation {
    var url: String
    var folderPath: String
    var pageNumber: Int
    var imageDownloader: SessionManager = {
        var configuration = SessionConfiguration()
        configuration.allowsCellularAccess = true
        configuration.maxConcurrentTasksLimit = 3
        let manager = SessionManager("imageDownloader", configuration: configuration)
        return manager
    }()
    
    init(url: String, folderPath: String, pageNumber: Int) {
        self.url = url
        self.folderPath = folderPath
        self.pageNumber = pageNumber
    }
    
    override func start() {
        guard !isCancelled else {
            state = .finished
            return
        }
        state = .executing
        main()
    }
    
    override func main() {
        let documentsURL = URL(fileURLWithPath: self.folderPath)
        imageDownloader.download(url, onMainQueue: false)?.success(handler: { (task) in
            if let image = UIImage(contentsOfFile: task.filePath) {
                ImageCache.default.store(image, forKey: task.url.path)
            }
            if self.isCancelled {
                try? FileManager.default.removeItem(at: documentsURL)
            }
        }).failure(handler: { (_) in
            self.main()
            if self.isCancelled {
                try? FileManager.default.removeItem(at: documentsURL)
            }
        })
//        imageDownloader.download(url, onMainQueue: false).success(handler: { (task) in
//
//        })
//        RequestManager.shared.getPageImageUrl(url: url) { imageUrl in
//            if let imageUrl = imageUrl {
//                let documentsURL = URL(fileURLWithPath: self.folderPath)
//                let fileURL = documentsURL.appendingPathComponent(String(format: "%04d.jpg", self.pageNumber))
//                let destination: DownloadRequest.Destination = { _, _ in
//                    return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
//                }
//                AF.download(imageUrl, to: destination).response { response in
//                    switch response.result {
//                    case .success(_):
//                        self.state = .finished
//                        if let image = UIImage(contentsOfFile: fileURL.path) {
//                            ImageCache.default.store(image, forKey: imageUrl)
//                        }
//                    case .failure(_):
//                        self.main()
//                    }
//                    if self.isCancelled {
//                        try? FileManager.default.removeItem(at: documentsURL)
//                    }
//                }
//            } else {
//                self.state = .finished
//            }
//        }
//    }
    
    
    
}

class DownloadManager: NSObject {
    static let shared = DownloadManager()
    var queues: [OperationQueue] = []
    var books: [String: Doujinshi] = [:]
    var sessionManager: SessionManager = {
        let manager = appDelegate.sessionManager
        manager.configuration.maxConcurrentTasksLimit = 2
        return manager
    }()
    
    func download(doujinshi: Doujinshi) {
        guard let gdata = doujinshi.gdata, doujinshi.pages.count != 0 else {return}
        let folderName = gdata.gid
        let path = documentURL.appendingPathComponent(folderName).path

        let urls = NSMutableArray.init(capacity: doujinshi.pages.count)
        let fileNames = NSMutableArray.init(capacity: doujinshi.pages.count)
        for (i, p) in doujinshi.pages.enumerated() {
            urls.add(p.url)
            fileNames.add((String(format: "%04d.jpg", i)))
        }
        sessionManager.multiDownload((NSArray(array: urls) as! [String]), fileNames: (NSArray(array: fileNames) as! [String]), onMainQueue: true) { (task) in
            let progress = task.progress.fractionCompleted
            print("下载中, 进度：\(progress)")
        }
        sessionManager.completion { [weak self] (manager) in
            if manager.status == .succeeded {
                // 下载成功
            } else {
                // 其他状态
            }
        }
        
//        let queue = OperationQueue()
//        queue.maxConcurrentOperationCount = 3
//        queue.isSuspended = queues.count != 0
//        queue.name = gdata.gid
//        queues.append(queue)
//        books[gdata.gid] = doujinshi
//
//        for (i, p) in doujinshi.pages.enumerated() {
//            let o = PageDownloadOperation(url: p.url, folderPath: path, pageNumber: i)
//            queue.addOperation(o)
//        }
//        queue.addObserver(self, forKeyPath: "operationCount", options: [.new], context: nil)
    }
    
    func cancelAllDownload() {
        let fileManager = FileManager.default
        for q in queues {
            q.removeObserver(self, forKeyPath: "operationCount")
            q.cancelAllOperations()
            let url = documentURL.appendingPathComponent(q.name!)
            try? fileManager.removeItem(at: url)
        }
        queues.removeAll()
        books.removeAll()
    }
    
    func deleteDownloaded(doujinshi: Doujinshi) {
        try? FileManager.default.removeItem(at: documentURL.appendingPathComponent(doujinshi.gdata!.gid))
        RealmManager.shared.deleteDoujinshi(book: doujinshi)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath, keyPath == "operationCount",
              let change = change, let count = change[.newKey] as? Int,
              let queue = object as? OperationQueue
        else {return}
        
        if count == 0 {
            RealmManager.shared.saveDownloadedDoujinshi(book: books[queue.name!]!)
            queues.remove(at: queues.firstIndex(of: queue)!)
            queue.removeObserver(self, forKeyPath: "operationCount")
            books.removeValue(forKey: queue.name!)
            if let nextQueue = queues.first {
                nextQueue.isSuspended = false
            }
        }
    }
}
