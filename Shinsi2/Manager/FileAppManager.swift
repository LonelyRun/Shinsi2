//
//  FileManager.swift
//  Shinsi2
//
//  Created by 钱进 on 2021/2/5.
//  Copyright © 2021 PowHu Yang. All rights reserved.
//

import UIKit

class FileAppManager:NSObject, UIDocumentPickerDelegate {

    static let `default` = FileAppManager()
    
    lazy var documentPickerVC = UIDocumentPickerViewController(documentTypes: ["public.content", "public.text"], in: UIDocumentPickerMode.open).then {
        $0.delegate = self
        $0.modalPresentationStyle = .formSheet
    }

    func downLoadWithFilePath(filePath: String) {
        
        
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first, url.startAccessingSecurityScopedResource() == true {
            NSFileCoordinator().coordinate(readingItemAt: url, options: NSFileCoordinator.ReadingOptions(rawValue: 0), error: nil) { (newUrl) in
                do {
                    let fileData = try Data.init(contentsOf: newUrl, options: Data.ReadingOptions.init(rawValue: 0))
                    let jsonString = String(data: fileData, encoding: .utf8)
                    if let models = [Author].deserialize(from: jsonString) {
                        
                        try! RealmManager.shared.realm.write {
                            RealmManager.shared.realm.delete(RealmManager.shared.author)
                        }
                        for item in models {
                            if item != nil {
                                try! RealmManager.shared.realm.write {
                                    RealmManager.shared.realm.add(item!)
                                }
                            }
                        }
                        NotificationCenter.default.post(name: NSNotification.Name.init(kUDViewerReloadData), object: nil)
                    }
                }catch{}
            }
            url.stopAccessingSecurityScopedResource()
        }
    }
}
