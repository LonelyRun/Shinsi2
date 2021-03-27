import Foundation
import Kingfisher

public extension Notification.Name {
    static let photoLoaded = Notification.Name("SSPHOTO_LOADING_DID_END_NOTIFICATION")
}

class SSPhoto: NSObject {
    
    var underlyingImage: UIImage?
    var urlString: String?
    var isLoading = false
    let imageCache = ImageCache.default
    let downloader = ImageDownloader.default
    
    init(URL url: String) {
        urlString = url
        super.init()
    }

    func loadUnderlyingImageAndNotify() {
        guard isLoading == false, underlyingImage == nil, urlString != nil else { return } 
        isLoading = true
        
        RequestManager.shared.getPageImageUrl(url: urlString!) { [weak self] url in
            guard let self = self else { return }
            guard let url = url else {
                self.imageLoadComplete()
                return
            }
            self.downloader.downloadImage(with: URL(string: url)!,
                                          options: [.downloadPriority(1)],
                                          progressBlock: nil) { result in
                switch result {
                    case .success(let value):
                        self.imageCache.store(value.image, forKey: self.urlString!)
                        self.underlyingImage = value.image
                        DispatchQueue.main.async {
                            self.imageLoadComplete()
                        }
                    case .failure(let error):
                        print(error)
                }
            }
        }
    }

    func checkCache() {
        guard urlString != nil else {
            return
        }
        if self.imageCache.isCached(forKey: urlString!) {
            self.imageCache.retrieveImage(forKey: urlString!, completionHandler: { (result) in
                switch result {
                case .success(let value):
                    self.underlyingImage = value.image
                    self.imageLoadComplete()
                case .failure(let error):
                    print(error)
                }
            })
        }else {
            guard let url = URL(string: urlString!) else {
                return
            }
            self.downloader.downloadImage(with: url,
                                          options: [.downloadPriority(1)],
                                          progressBlock: nil) { result in
                switch result {
                    case .success(let value):
                        self.imageCache.store(value.image, forKey: self.urlString!)
                        self.underlyingImage = value.image
                        DispatchQueue.main.async {
                            self.imageLoadComplete()
                        }
                    case .failure(let error):
                        print(error)
                }
            }
            
        }
    }

    func imageLoadComplete() {
        isLoading = false
        NotificationCenter.default.post(name: .photoLoaded, object: self)
    }
}
