//
//  SecurityView.swift
//  Shinsi2
//
//  Created by 钱进 on 2021/4/1.
//  Copyright © 2021 PowHu Yang. All rights reserved.
//

import Foundation
import UIKit

class SecurityView: UIView {
    
    static let instance = SecurityView()
    
    override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        alpha = 0
        backgroundColor = .black
        let imageView = UIImageView(image: UIImage(named: "splash_icon")).then {
            let screenSize = UIScreen.main.bounds.size
            let f: CGFloat = 200
            $0.frame = CGRect(x: (screenSize.width - f)/2, y: (screenSize.height - f)/2, width: f, height: f)
        }
        addSubview(imageView)
    }
    
    static func show () {
        UIView.animate(withDuration: 0.5) {
            instance.alpha = 1
        } completion: { (isFinished) in
            UIApplication.shared.keyWindow?.addSubview(instance)
        }
    }
    
    static func hide () {
        UIView.animate(withDuration: 0.5) {
            instance.alpha = 0
        } completion: { (isFinshed) in
            instance.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {fatalError("init(coder:) has not been implemented")}
    
    
}
