import UIKit
import Kingfisher

class ImageManager {
    static let shared: ImageManager = ImageManager()
    let imageCache = ImageCache.default
    private var downloadingUrls: Set<URL> = Set<URL>()
    
    func getCache(forKey name: String) -> UIImage? {
        var image = UIImage.self();
        if imageCache.isCached(forKey: name) {
            let signalObj = DispatchSemaphore(value: 0)
            imageCache.retrieveImage(forKey: name, completionHandler: { (result) in
                switch result {
                case .success(let value):
                    image = value.image!
                case .failure(let error):
                    print(error)
                }
                signalObj.signal()
            })
            signalObj.wait()
        }
        return image
    }
    
    func prefetch(urls: [URL]) {
        var prefetchUrls: [URL] = []
        for url in urls {
            guard !downloadingUrls.contains(url) else {return}
            guard getCache(forKey: url.absoluteString) == nil else {return}
            downloadingUrls.insert(url)
            prefetchUrls.append(url)
        }
        
        let prefetcher = ImagePrefetcher.init(urls: urls, options: [.downloadPriority(1.0)]) { (skippedResources, failedResources, completedResources) in
            prefetchUrls.forEach { self.downloadingUrls.remove($0) }
        }
        prefetcher.start()
    }
}
