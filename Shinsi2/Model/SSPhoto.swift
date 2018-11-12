import Foundation
import SDWebImage

public extension Notification.Name {
    public static let photoLoaded = Notification.Name("SSPHOTO_LOADING_DID_END_NOTIFICATION")
}

class SSPhoto : NSObject {
    
    var underlyingImage :UIImage?
    var urlString :String
    var isLoading = false
    let imageCache = SDWebImageManager.shared().imageCache!
    
    init(URL url : String) {
        urlString = url
        super.init()
    }

    func loadUnderlyingImageAndNotify() {
        guard isLoading == false, underlyingImage == nil else { return } 
        isLoading = true
        
        RequestManager.shared.getPageImageUrl(url: urlString) { [weak self] url in
            guard let self = self else { return }
            guard let url = url else {
                self.imageLoadComplete()
                return
            }
            SDWebImageDownloader.shared().downloadImage( with: URL(string: url)! , options: [.highPriority , .handleCookies , .useNSURLCache], progress:nil , completed: { [weak self] image, data, error, success in
                guard let self = self else { return }
                self.imageCache.store(image, forKey: self.urlString)
                self.underlyingImage = image
                DispatchQueue.main.async {
                    self.imageLoadComplete()
                }
            })
        }
    }

    func checkCache() {
        if let memoryCache = imageCache.imageFromMemoryCache(forKey: urlString) {
            underlyingImage = memoryCache
            imageLoadComplete()
            return
        }
        
        imageCache.queryCacheOperation(forKey: urlString) { [weak self] image, _,_ in
            if let diskCache = image ,let self = self {
                self.underlyingImage = diskCache
                self.imageLoadComplete()
            }
        }
    }

    func imageLoadComplete() {
        isLoading = false
        NotificationCenter.default.post(name: .photoLoaded, object: self)
    }
}
