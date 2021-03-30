import UIKit
import Kingfisher

class ImageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var  loadingView: LoadingView?
    static let downProcessor = DownsamplingImageProcessor(size: .init(width: 200, height: CGFloat.infinity))
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
    }
}

class ListCell: ImageCell {
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var conventionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var pageCountLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
}

class CommentCell: UITableViewCell {
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
}

class ScrollingImageCell: UICollectionViewCell { 
    var imageView: UIImageView = UIImageView()
    var scrollView: UIScrollView = UIScrollView()
    var dTapGR: UITapGestureRecognizer!
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            setNeedsLayout()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scrollView.frame = bounds
        scrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        scrollView.maximumZoomScale = 4
        scrollView.minimumZoomScale = 1
        scrollView.delegate = self
        scrollView.contentMode = .center
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        
        dTapGR = UITapGestureRecognizer(target: self, action: #selector(doubleTap(gr:)))
        dTapGR.numberOfTapsRequired = 2 
        dTapGR.delegate = self
        addGestureRecognizer(dTapGR)
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        let newCenter = imageView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    @objc func doubleTap(gr: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale / 2, center: gr.location(in: gr.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        var size: CGSize
        if let image = imageView.image {
            let containerSize = bounds.size
            if containerSize.width / containerSize.height < image.size.width / image.size.height {
                size = CGSize(width: containerSize.width, height: containerSize.width * image.size.height / image.size.width )
            } else {
                size = CGSize(width: containerSize.height * image.size.width / image.size.height, height: containerSize.height )
            }
        } else {
            size = bounds.size
        }
        size = CGSize(width: max(bounds.width, size.width), height: max(bounds.height, size.height))
        imageView.frame = CGRect(origin: .zero, size: size)
        scrollView.contentSize = size
        centerIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        scrollView.setZoomScale(1, animated: false)
        imageView.kf.cancelDownloadTask()
    }
    
    func centerIfNeeded() {
        var inset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        if scrollView.contentSize.height < scrollView.bounds.height {
            let insetV = (scrollView.bounds.height - scrollView.contentSize.height)/2
            inset.top += insetV
            inset.bottom = insetV
        }
        if scrollView.contentSize.width < scrollView.bounds.width {
            let insetH = (scrollView.bounds.width - scrollView.contentSize.width)/2
            inset.left = insetH
            inset.right = insetH
        }
        scrollView.contentInset = inset
    }
}

extension ScrollingImageCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerIfNeeded()
    }
}

extension ScrollingImageCell: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer as? UITapGestureRecognizer != nil, otherGestureRecognizer as? UITapGestureRecognizer != nil else {return false}
        return true
    }
}
