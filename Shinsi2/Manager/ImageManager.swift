import UIKit
import Kingfisher

class ImageManager {
    static let shared: ImageManager = ImageManager()
    let imageCache = ImageCache.default
    private var downloadingUrls: Set<URL> = Set<URL>()
    let modifier = AnyModifier { request in
        var re = request
        re.httpShouldHandleCookies = true;
        re.setValue(Defaults.URL.host, forHTTPHeaderField: "Referer")
        var array = Array<String>()
        for cookie in HTTPCookieStorage.shared.cookies(for: URL(string: Defaults.URL.host)!)! {
            array.append("\(cookie.name)=\(cookie.value)")
        }
        re.setValue(array.joined(separator: ";"), forHTTPHeaderField: "Cookie")
        return re
    }

    
    func getCache(forKey name: String) -> UIImage? {
        if imageCache.isCached(forKey: name) {
            var image : UIImage?;
            let semaphore = DispatchSemaphore(value: 1)
            semaphore.wait()
            imageCache.retrieveImage(forKey: name, options: [.loadDiskFileSynchronously], completionHandler: { (result) in
                switch result {
                case .success(let value):
                    image = value.image!
                case .failure(_):
                    image = nil
                }
                semaphore.signal()
            })
            return image
        }else {
            return nil
        }
    }
    
    func prefetch(urls: [URL]) {
        var prefetchUrls: [URL] = []
        for url in urls {
            guard !downloadingUrls.contains(url) else {return}
            guard getCache(forKey: url.absoluteString) == nil else {return}
            downloadingUrls.insert(url)
            prefetchUrls.append(url)
        }
        ImagePrefetcher(urls: urls,
                        options: [.downloadPriority((URLSessionTask.highPriority)),
                                  .backgroundDecode,
                                  .requestModifier(modifier)],
                        progressBlock: nil) { (skippedResources, failedResources, completedResources) in
            prefetchUrls.forEach { self.downloadingUrls.remove($0) }
        }.start()
    }
}
