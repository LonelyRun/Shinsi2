import UIKit

class InsetLabel: UILabel {
    
    @IBInspectable var topInset: CGFloat = 4.0
    @IBInspectable var leftInset: CGFloat = 4.0
    @IBInspectable var bottomInset: CGFloat = 4.0
    @IBInspectable var rightInset: CGFloat = 4.0
    
    var insets: UIEdgeInsets {
        get {
            return UIEdgeInsets.init(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        }
        set {
            topInset = newValue.top
            leftInset = newValue.left
            bottomInset = newValue.bottom
            rightInset = newValue.right
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var adjSize = super.sizeThatFits(size)
        adjSize.width += leftInset + rightInset
        adjSize.height += topInset + bottomInset
        return adjSize
    }
    
    override var intrinsicContentSize: CGSize {
        let systemContentSize = super.intrinsicContentSize
        let adjustSize = CGSize(width: systemContentSize.width + leftInset + rightInset, height: systemContentSize.height + topInset + bottomInset) 
        if adjustSize.width > preferredMaxLayoutWidth && preferredMaxLayoutWidth != 0 {
            let constraintSize = CGSize(width: preferredMaxLayoutWidth - (leftInset + rightInset), height: .greatestFiniteMagnitude)
            let newSize = super.sizeThatFits(constraintSize)
            return CGSize(width: preferredMaxLayoutWidth, height: ceil(newSize.height) + topInset + bottomInset)
        } else {
            return adjustSize
        }
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
}

