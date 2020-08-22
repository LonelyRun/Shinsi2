import UIKit
import SDWebImage

class ImageManager {
    static let shared: ImageManager = ImageManager()
    let imageCache = SDWebImageManager.shared().imageCache!
    private var downloadingUrls: Set<URL> = Set<URL>()
    
    func getCache(forKey name: String) -> UIImage? {
        return imageCache.imageFromMemoryCache(forKey: name) ?? imageCache.imageFromDiskCache(forKey: name)
    }
    
    func prefetch(urls: [URL]) {
        var prefetchUrls: [URL] = []
        for url in urls {
            guard !downloadingUrls.contains(url) else {return}
            guard getCache(forKey: url.absoluteString) == nil else {return}
            downloadingUrls.insert(url)
            prefetchUrls.append(url)
        }
        
        let prefetcher = SDWebImagePrefetcher()
        prefetcher.options = [.highPriority, .handleCookies]
        prefetcher.prefetchURLs(urls, progress: nil) { (_, _) in
            prefetchUrls.forEach { self.downloadingUrls.remove($0) }
        }
        
    }
}
