import UIKit

class QuickScrollBar: NSObject {
    
    private(set) weak var scrollView: UIScrollView!
    private(set) weak var target: UIScrollViewDelegate?
    
    private(set) var gestureRecognizeView: UIView = UIView()
    private(set) var indicatorView: UIView = UIView()
    private(set) var textLabel: BadgeLabel = BadgeLabel()
    private(set) var barView: UIView = UIView()
    
    private var keyValueObservations = [NSKeyValueObservation]()
    private lazy var panGesture: UIPanGestureRecognizer = { return UIPanGestureRecognizer(target: self, action: #selector(pan(ges:)))}()
    
    private var hideTimer: Timer?
    
    // Compute Properties
    private var safeAreaHeight: CGFloat { return scrollView.bounds.height - scrollView.safeAreaInsets.top - scrollView.safeAreaInsets.bottom }
    private var maxContentOffsetY: CGFloat { return scrollView.contentSize.height - safeAreaHeight }
    private var contentOffsetY: CGFloat { return scrollView.contentOffset.y + scrollView.adjustedContentInset.top }
    
    // Custom Properties
    public var textForIndexPath: ((IndexPath) -> String)?
    public var gestureRecognizeWidth: CGFloat = 36 {
        didSet {
            gestureRecognizeView.getConstraint(with: "gesWidth")?.constant = gestureRecognizeWidth
        }
    }
    public var indicatorSize: CGSize = CGSize(width: 36, height: 36) {
        didSet {
            indicatorView.getConstraint(with: "indWidth")?.constant = indicatorSize.width
            indicatorView.getConstraint(with: "indHeight")?.constant = indicatorSize.height
        }
    }
    public var indicatorRightMargin: CGFloat = 0 {
        didSet {
            scrollView.getConstraint(with: "indRightMargin")?.constant = -indicatorRightMargin
        }
    }
    public var indicatorCornerRadius: CGFloat = 18 {
        didSet {
            indicatorView.layer.cornerRadius = indicatorCornerRadius
        }
    }
    public var barWidth: CGFloat = 3 {
        didSet {
            barView.getConstraint(with: "barWidth")?.constant = barWidth
            barView.layer.cornerRadius = barWidth/2
        }
    }
    public var barOffset: CGFloat = 0 {
        didSet {
            gestureRecognizeView.getConstraint(with: "barOffset")?.constant = barOffset
        }
    }
    public var isBarHidden: Bool = false {
        didSet {
            barView.isHidden = isBarHidden
        }
    }
    public var textOffset: CGFloat = 20 {
        didSet {
            indicatorView.getConstraint(with: "textOffset")?.constant = -textOffset
        }
    }
    public var draggingTextOffset: CGFloat = 20 {
        didSet {
            indicatorView.getConstraint(with: "textOffset")?.constant = -textOffset
        }
    }
    public var color: UIColor = UIColor(white: 0.2, alpha: 1) {
        didSet {
            indicatorView.backgroundColor = color
            textLabel.backgroundColor = color
        }
    }
    public var barColor: UIColor = UIColor(white: 0.1, alpha: 0.6) {
        didSet {
            barView.backgroundColor = barColor
        }
    }
    public var hideDelay: Double = 1.5
    public var textColor: UIColor = .white {
        didSet {
            textLabel.textColor = textColor
        }
    }
    public var font: UIFont = UIFont.boldSystemFont(ofSize: 14) {
        didSet {
            textLabel.font = font
        }
    }
    
    init(scrollView: UIScrollView, target: UIScrollViewDelegate? = nil) {
        super.init()
        self.target = target
        self.scrollView = scrollView
        setup()
    }
    
    private func setup() {
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        let contentSizeObservation = scrollView.observe(\.contentSize, options: [.new]) {[unowned self] (_, _) in
            self.updatePosition(animated: true)
            self.updateText()
        }
        keyValueObservations.append(contentSizeObservation)
        
        scrollView.addSubview(gestureRecognizeView)
        gestureRecognizeView.translatesAutoresizingMaskIntoConstraints = false
        let gesWidth = gestureRecognizeView.widthAnchor.constraint(equalToConstant: gestureRecognizeWidth)
        gesWidth.identifier = "gesWidth"
        gesWidth.isActive = true
        gestureRecognizeView.topAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        gestureRecognizeView.bottomAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        gestureRecognizeView.rightAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.rightAnchor, constant: 0).isActive = true
        gestureRecognizeView.alpha = 0
        gestureRecognizeView.addGestureRecognizer(panGesture)
        panGesture.delegate = self
        
        gestureRecognizeView.addSubview(barView)
        barView.translatesAutoresizingMaskIntoConstraints = false
        let barWidthCs = barView.widthAnchor.constraint(equalToConstant: barWidth)
        barWidthCs.identifier = "barWidth"
        barWidthCs.isActive = true
        barView.topAnchor.constraint(equalTo: gestureRecognizeView.topAnchor, constant: 10).isActive = true
        let barOffsetCs = barView.centerXAnchor.constraint(equalTo: gestureRecognizeView.centerXAnchor, constant: barOffset)
        barOffsetCs.identifier = "barOffset"
        barOffsetCs.isActive = true
        barView.bottomAnchor.constraint(equalTo: gestureRecognizeView.bottomAnchor, constant: -10).isActive = true
        barView.backgroundColor = barColor
        barView.layer.cornerRadius = barWidth/2
        barView.isUserInteractionEnabled = false
        barView.isHidden = isBarHidden
        
        gestureRecognizeView.addSubview(indicatorView)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        let indWHeight = indicatorView.heightAnchor.constraint(equalToConstant: indicatorSize.height)
        indWHeight.identifier = "indHeight"
        indWHeight.isActive = true
        let indWidth = indicatorView.widthAnchor.constraint(equalToConstant: indicatorSize.width)
        indWidth.identifier = "indWidth"
        indWidth.isActive = true
        let indRightMargin = indicatorView.rightAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.rightAnchor, constant: -indicatorRightMargin)
        indRightMargin.identifier = "indRightMargin"
        indRightMargin.isActive = true
        indicatorView.topAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        indicatorView.layer.cornerRadius = 18
        indicatorView.backgroundColor = color
        indicatorView.layer.shadowColor = UIColor.black.cgColor
        indicatorView.layer.shadowOpacity = 0.6
        indicatorView.layer.shadowOffset = CGSize(width: 0, height: 2)
        indicatorView.layer.shadowRadius = 2
        indicatorView.isUserInteractionEnabled = false
        
        indicatorView.addSubview(textLabel)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.centerYAnchor.constraint(equalTo: indicatorView.centerYAnchor, constant: 0).isActive = true
        let textOffsetCs = textLabel.rightAnchor.constraint(equalTo: indicatorView.leftAnchor, constant: -textOffset)
        textOffsetCs.identifier = "textOffset"
        textOffsetCs.isActive = true
        textLabel.backgroundColor = color
        textLabel.textColor = textColor
        textLabel.font = font
    }
    
    private func updatePosition(animated: Bool = false) {
        guard indicatorView.layer.animationKeys() == nil else {return}
        let percentage = contentOffsetY / maxContentOffsetY
        let transformY = min(max(0, (safeAreaHeight - indicatorView.bounds.height) * percentage), safeAreaHeight - indicatorView.bounds.height)
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
                self.indicatorView.layer.transform = CATransform3DMakeTranslation(0, transformY, 0)
            }, completion: nil)
        } else {
            indicatorView.layer.transform = CATransform3DMakeTranslation(0, transformY, 0)
        }
    }
    
    private func updateText() {
        var text: String = ""
        let percentage = contentOffsetY / maxContentOffsetY
        if let scrollView = scrollView as? UICollectionView, scrollView.indexPathsForVisibleItems.count > 0 {
            let indexPaths = scrollView.indexPathsForVisibleItems.sorted()
            let currentIndex = Int(floor(CGFloat(indexPaths.count) * percentage))
            if  0..<indexPaths.count ~= currentIndex {
                let indexPath = indexPaths[currentIndex]
                text = textForIndexPath?(indexPath) ?? ""
            } else if let indexPath = currentIndex < 0 ? indexPaths.first : indexPaths.last {
                text = textForIndexPath?(indexPath) ?? ""
            }
        } else if let scrollView = scrollView as? UITableView, let indexPaths = scrollView.indexPathsForVisibleRows {
            let indexPath = indexPaths[Int(floor(CGFloat(indexPaths.count) * percentage))]
            text = textForIndexPath?(indexPath) ?? ""
        }
        textLabel.text = text
        textLabel.isHidden = text.isEmpty
    }
    
    public func show() {
        gestureRecognizeView.alpha = 1
        gestureRecognizeView.layer.transform = CATransform3DIdentity
    }
    
    @objc public func hide() {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.gestureRecognizeView.alpha = 0
            self.gestureRecognizeView.layer.transform = CATransform3DMakeTranslation(self.gestureRecognizeView.bounds.width, 0, 0)
        }, completion: nil)
    }
}

extension QuickScrollBar: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePosition()
        updateText()
        target?.scrollViewDidScroll?(scrollView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        show()
        target?.scrollViewWillBeginDragging?(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate && panGesture.state == .possible {
            hideTimer?.invalidate()
            hideTimer = Timer.scheduledTimer(timeInterval: hideDelay, target: self, selector: #selector(hide), userInfo: nil, repeats: false)
        }
        target?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if panGesture.state == .possible {
            hideTimer?.invalidate()
            hideTimer = Timer.scheduledTimer(timeInterval: hideDelay, target: self, selector: #selector(hide), userInfo: nil, repeats: false)
        }
        target?.scrollViewDidEndDecelerating?(scrollView)
    }
   
    //UIScrollView delegate chaining
    override func responds(to aSelector: Selector!) -> Bool {
        if QuickScrollBar.instancesRespond(to: aSelector) {
            return true
        }
        return target?.responds(to: aSelector) ?? QuickScrollBar.instancesRespond(to: aSelector)
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
}

extension QuickScrollBar: UIGestureRecognizerDelegate {
    
    @objc private func pan(ges: UIPanGestureRecognizer) {
        switch ges.state {
        case .began:
            hideTimer?.invalidate()
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 10, options: [], animations: {
                self.textLabel.layer.transform = CATransform3DTranslate(CATransform3DMakeScale(1.3, 1.3, 1), -self.draggingTextOffset, 0, 0)
            }, completion: nil)
        case .changed:
            let translate = ges.location(in: gestureRecognizeView)
            let translateY = min(max(0, translate.y), safeAreaHeight)
            let percentage = translateY / safeAreaHeight
            let contentOffsetY = maxContentOffsetY * percentage - scrollView.adjustedContentInset.top
            scrollView.contentOffset = CGPoint(x: 0, y: contentOffsetY)
        default:
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: [], animations: {
                self.textLabel.layer.transform = CATransform3DIdentity
            }, completion: nil)
            hideTimer = Timer.scheduledTimer(timeInterval: hideDelay, target: self, selector: #selector(hide), userInfo: nil, repeats: false)
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: gestureRecognizer.view)
        return indicatorView.frame.contains(location)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

class BadgeLabel: UILabel {
    
    var insets: UIEdgeInsets = UIEdgeInsets.init(top: 6, left: 14, bottom: 6, right: 14)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    func setup() {
        clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.size.height / 2
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var adjSize = super.sizeThatFits(size)
        adjSize.width += insets.right + insets.left
        adjSize.height += insets.top + insets.bottom
        return adjSize
    }
    
    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.width += insets.right + insets.left
        contentSize.height += insets.top + insets.bottom
        return contentSize
    }
}

fileprivate extension UIView {
    func getConstraint(with identifier: String) -> NSLayoutConstraint? {
        return constraints.filter { $0.identifier == identifier }.first
    }
}
