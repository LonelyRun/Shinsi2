import UIKit

class DownloadBubble: UIView {
    static let shared = DownloadBubble()
    
    private var imageView = UIImageView()
    private var circleLayer = CAShapeLayer()
    private var badgeLabel = UILabel()
    private var lineWidth = CGFloat(4)
    private var observingQueue: OperationQueue?
    weak var viewController: UIViewController?
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        frame = CGRect(x: 0, y: 0, width: 70, height: 70)
        layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
        layer.shadowRadius = 2.5
        layer.shadowOpacity = 0.7
        layer.shadowOffset = CGSize(width: 0, height: 4)
        
        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = bounds.size.width/2
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor(white: 0.3, alpha: 1).cgColor
        addSubview(imageView)
        
        circleLayer.frame = bounds.insetBy(dx: lineWidth/2, dy: lineWidth/2)
        circleLayer.strokeColor = kMainColor.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.path = UIBezierPath(ovalIn: circleLayer.bounds).cgPath
        circleLayer.lineCap = CAShapeLayerLineCap.round
        circleLayer.lineWidth = lineWidth
        circleLayer.transform = CATransform3DMakeRotation(-CGFloat.pi/2, 0, 0, 1)
        circleLayer.strokeEnd = 0
        layer.addSublayer(circleLayer)
        
        badgeLabel.backgroundColor = kMainColor
        badgeLabel.textColor = UIColor.white
        badgeLabel.font = UIFont.systemFont(ofSize: 13)
        badgeLabel.textAlignment = .center
        badgeLabel.clipsToBounds = true
        addSubview(badgeLabel)
        
        let stop = UIView(frame: bounds.insetBy(dx: bounds.width/2 - 10, dy: bounds.height/2 - 10))
        stop.layer.cornerRadius = 2
        stop.clipsToBounds = true
        stop.backgroundColor = kMainColor
        stop.isUserInteractionEnabled = false
        addSubview(stop)
        
        transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
    }
    
    func show(on vc: UIViewController) {
        if superview != nil { removeFromSuperview() }
        
        viewController = vc
        vc.view.addSubview(self)
        let inset = CGFloat(24)
        
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 70),
            heightAnchor.constraint(equalToConstant: 70),
            leftAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.leftAnchor, constant: inset),
            bottomAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.bottomAnchor, constant: -inset)
        ])
        
        UIView.animate(
            withDuration: 1.5,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 1,
            options: [.curveEaseInOut],
            animations: {
            self.alpha = 1
            self.transform = .identity
        }, completion: nil)
        
        observerNextQueue()
    }
    
    func dismiss() {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut],
            animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }, completion: { _ in
            self.viewController = nil
            self.circleLayer.strokeEnd = 0
            self.removeFromSuperview()
        })
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let vc = viewController,
            let queue = DownloadManager.shared.queues.first
            else { return }
        queue.isSuspended = true
        let alert = UIAlertController(title: "Cancel All Download", message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Yes", style: .default) { _ in
            self.cancelAllDownload()
            self.dismiss()
        }
        let cancel = UIAlertAction(title: "No", style: .cancel, handler: { _ in queue.isSuspended = false })
        alert.addAction(ok)
        alert.addAction(cancel)
        vc.present(alert, animated: true, completion: nil)
    }
    
    func cancelAllDownload() {
        observingQueue?.removeObserver(self, forKeyPath: "operationCount")
        DownloadManager.shared.cancelAllDownload()
    }
    
    func updateBadge() {
        let count = DownloadManager.shared.queues.count
        badgeLabel.text = String(count)
        badgeLabel.sizeToFit()
        let r = badgeLabel.bounds.insetBy(dx: -2, dy: -2)
        let f = CGRect(origin: .zero, size: CGSize(width: max(r.width, r.height), height: max(r.width, r.height)))
        badgeLabel.frame = f
        badgeLabel.layer.cornerRadius = f.width/2
        badgeLabel.center = CGPoint(x: bounds.maxX, y: bounds.minY)
    }
    
    func observerNextQueue() {
        if let queue = DownloadManager.shared.queues.first, let doujinshi = DownloadManager.shared.books[queue.name!] {
            imageView.kf.setImage(with: URL(string: doujinshi.coverUrl))
            observingQueue = queue
            queue.addObserver(self, forKeyPath: "operationCount", options: [.new], context: nil)
            updateBadge()
        } else {
            dismiss()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath, keyPath == "operationCount",
            let change = change, let count = change[.newKey] as? Int,
            let queue = object as? OperationQueue,
            let doujinshi = DownloadManager.shared.books[queue.name!]
            else {return}
        
        circleLayer.strokeEnd = 1 - CGFloat(count) / CGFloat(doujinshi.gdata!.filecount)
        
        if count == 0 {
            queue.removeObserver(self, forKeyPath: "operationCount")
            observingQueue = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.observerNextQueue()
            })
        }
    }
}
