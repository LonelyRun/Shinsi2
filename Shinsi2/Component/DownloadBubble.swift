import UIKit
import Kingfisher

class DownloadBubble: UIView {
    static let shared = DownloadBubble()
    
    private var imageView = UIImageView()
    private var circleLayer = CAShapeLayer()
    private var badgeLabel = UILabel()
    private var lineWidth = CGFloat(4)
    private var observingQueue: OperationQueue?
    weak var viewController: UIViewController?
    let imgDownloaders = appDelegate.imgDownloaders
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
    
        NotificationCenter.default.addObserver(forName:  Notification.Name(rawValue: "downloadProgress"), object: nil, queue: nil) { [weak self] (notification) in
            let array = notification.object as! Array<Any>
            let cover = array.first as! String
            let value = array.last as! CGFloat
            let mod = (self?.modifier)! as AsyncImageDownloadRequestModifier
            self?.imageView.kf.setImage(with: URL(string: cover), options: [.loadDiskFileSynchronously, .cacheOriginalImage, .requestModifier(mod)])
            if value < 1.0 {
                self?.circleLayer.strokeEnd = value
                self?.updateBadge()
            } else {
                self?.dismiss()
            }
            
        }
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
        guard let vc = viewController
            else { return }
        let alert = UIAlertController(title: "Cancel All Download", message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Yes", style: .default) { _ in
            self.cancelAllDownload()
            self.dismiss()
        }
        let cancel = UIAlertAction(title: "No", style: .cancel, handler: { _ in })
        alert.addAction(ok)
        alert.addAction(cancel)
        vc.present(alert, animated: true, completion: nil)
    }
    
    func cancelAllDownload() {
        DownloadManager.shared.cancelAllDownload()
    }
    
    func updateBadge() {
        let count = imgDownloaders.count
        badgeLabel.text = String(count)
        badgeLabel.sizeToFit()
        let r = badgeLabel.bounds.insetBy(dx: -2, dy: -2)
        let f = CGRect(origin: .zero, size: CGSize(width: max(r.width, r.height), height: max(r.width, r.height)))
        badgeLabel.frame = f
        badgeLabel.layer.cornerRadius = f.width/2
        badgeLabel.center = CGPoint(x: bounds.maxX, y: bounds.minY)
    }
    
}
