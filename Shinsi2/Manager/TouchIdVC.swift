//
//  TouchIdVC.swift
//  Shinsi2
//
//  Created by admin on 2018/12/25.
//  Copyright © 2018 PowHu Yang. All rights reserved.
//

import UIKit
import LocalAuthentication

class TouchIdVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        TouchIdTool.shareTool.showTouchId { (isSuccess) in
            if isSuccess {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}
