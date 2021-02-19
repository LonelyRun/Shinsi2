//
//  FileManager.swift
//  Shinsi2
//
//  Created by 钱进 on 2021/2/5.
//  Copyright © 2021 PowHu Yang. All rights reserved.
//

import UIKit

class FileAppManager: NSObject, UIDocumentPickerDelegate {

    static let `default` = FileAppManager()
    
    lazy var documentPickerVC = UIDocumentPickerViewController(documentTypes: ["public.content", "public.text"], in: UIDocumentPickerMode.open).then {
        $0.delegate = self
        $0.modalPresentationStyle = .formSheet
    }

    static func exportToFile () {
        
        var modelArr: [Author] = []
        let dataArr = RealmManager.shared.author.map{$0}
        dataArr.forEach { (author) in
            modelArr.append(author)
        }
        guard var dataString = modelArr.toJSONString(prettyPrint: true) else {
            return
        }
        dataString = (dataString as NSString).replacingOccurrences(of: "\\", with: "")
        guard let data = dataString.data(using: .utf8) else {
            return
        }
        guard let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first  else {
            return
        }
        let filePath = (cacheDirectory as NSString).appendingPathComponent("shinsi.json")
        let fileManager = FileManager.default
        if (fileManager.fileExists(atPath: filePath)) {
            try? fileManager.removeItem(atPath: filePath)
        }
        fileManager.createFile(atPath: filePath, contents: data, attributes: nil)

        let documentPicker = UIDocumentPickerViewController(url: URL.init(fileURLWithPath: filePath), in: .exportToService)
        UIApplication.shared.keyWindow?.rootViewController?.present(documentPicker, animated: true, completion: nil)
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
