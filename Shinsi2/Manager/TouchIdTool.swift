//
//  TouchIdTool.swift
//  Shinsi2
//
//  Created by admin on 2018/12/25.
//  Copyright © 2018 PowHu Yang. All rights reserved.
//

import UIKit
import LocalAuthentication

class TouchIdTool {

    static let shareTool = TouchIdTool()
    
    static func isEnableTouchId() -> Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    static func isSupportDeviceOwnerAuth() -> Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }
    
    func showTouchId(handler: @escaping ((Bool) -> Void)) {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "指纹验证") { (success, error) in
            if success {
                handler(true)
            } else {
                handler(false)
            }
        }
    }
}
