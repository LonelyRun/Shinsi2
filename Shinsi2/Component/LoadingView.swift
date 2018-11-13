import UIKit

class LoadingView: UIView {
    
    private let leftBeard = UIImageView(image: #imageLiteral(resourceName: "beard_right_s"))
    private let rightBeard = UIImageView(image: #imageLiteral(resourceName: "beard_left_s"))
    @IBInspectable var maxAlpha: CGFloat = 1
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 48, height: 48)))
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
        addSubview(leftBeard)
        addSubview(rightBeard)
        leftBeard.translatesAutoresizingMaskIntoConstraints = false
        rightBeard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leftBeard.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            leftBeard.rightAnchor.constraint(equalTo: centerXAnchor, constant: 1),
            rightBeard.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            rightBeard.leftAnchor.constraint(equalTo: centerXAnchor, constant: -1),
        ])
        
       show(animated: false)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 48, height: 48)
    }
    
    func show(animated: Bool = true) {
        [leftBeard,rightBeard].enumerated().forEach {
            $0.element.layer.removeAllAnimations()
            let ani = CABasicAnimation(keyPath: "transform.rotation.z")
            ani.toValue = CGFloat.pi * 0.13 * ($0.offset == 0 ? 1 : -1)
            ani.autoreverses = true
            ani.repeatCount = Float.greatestFiniteMagnitude
            ani.duration = 1.2
            $0.element.layer.add(ani, forKey: "rotate")
        }
        UIView.animate(withDuration: animated ? 0.3 : 0, delay: 0, options: [.curveEaseOut], animations: {
            self.alpha = self.maxAlpha
            self.transform = .identity
        }, completion: nil)
    }
    
    func hide(animated: Bool = true) {
        UIView.animate(withDuration: animated ? 0.2 : 0, delay: 0, options: [.curveEaseIn], animations: {
            self.alpha = 0
            self.transform = .init(scaleX: 1.3, y: 1.3)
        }, completion: nil)
    }

}
