//
//  AuthorVC.swift
//  Shinsi2
//
//  Created by 钱进 on 2021/2/2.
//  Copyright © 2021 PowHu Yang. All rights reserved.
//

import UIKit
import Then


let LabelHeight = 50.0
let CollectionViewWidth = 130.0
let CollectionViewHeight = 137.0


class AuthorVC: UITableViewController {
    
    static let shareInstance = AuthorVC()
    
    var modelArr: [Author] = []
    var selectHandler: ((_ author: String) -> Void)?
    private var backGesture: InteractiveBackGesture?
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(kUDViewerReloadData), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AuthorTableViewCell.self, forCellReuseIdentifier: "cell")
        backGesture = InteractiveBackGesture(viewController: self, toView: tableView)

        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name.init(kUDViewerReloadData), object: nil)
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(named: "import"), style: .plain, target: self, action: #selector(importFile)),
            UIBarButtonItem(image: UIImage(named: "export"), style: .plain, target: self, action: #selector(exportFile))]
    }
    
    @objc private func importFile () {
        present(FileAppManager.default.documentPickerVC, animated: true, completion: nil)
    }
    
    @objc private func exportFile () {
        FileAppManager.exportToFile()
    }

    
    @objc private func reloadData () {
        modelArr = RealmManager.shared.author.map{$0}
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelArr.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! AuthorTableViewCell
        cell.model = modelArr[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectHandler?("\(modelArr[indexPath.row].author)")
        navigationController?.popViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let model = modelArr[indexPath.item]
            RealmManager.shared.deleteAuthor(author: model)
            reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(LabelHeight + CollectionViewHeight)
    }
}


private class AuthorTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var model: Author? {
        didSet {
            authorLabel.text = "     \(model?.author ?? "")"
            collectionView.reloadData()
        }
    }
    
    private func genster(index: Int) {
        
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(authorLabel)
        contentView.addSubview(collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model?.covers.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! AuthorCollectionViewCell
        cell.cover = model?.covers[indexPath.item]
        cell.model = model
        return cell
    }


    private lazy var collectionView = UICollectionView(frame: CGRect(x: 0, y: LabelHeight, width: Double(Int(UIScreen.main.bounds.width)), height: CollectionViewHeight), collectionViewLayout: UICollectionViewFlowLayout().then {
        $0.scrollDirection = .horizontal
        $0.minimumLineSpacing = 0
        $0.minimumInteritemSpacing = 0
        $0.itemSize = CGSize.init(width: CollectionViewWidth, height: CollectionViewHeight)
    }).then {
        $0.delegate = self
        $0.dataSource = self
        $0.register(AuthorCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        $0.showsHorizontalScrollIndicator = false
        $0.backgroundColor = .white
    }
    
    
    private lazy var authorLabel = UILabel().then {
        $0.textColor = .black
        $0.frame = CGRect(x: 0, y: 0, width: Int(UIScreen.main.bounds.width), height: Int(LabelHeight))
        $0.backgroundColor = .white
        $0.font = UIFont.boldSystemFont(ofSize: 17)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}


private class AuthorCollectionViewCell: UICollectionViewCell {
    
    var cover: String? {
        didSet {
            if let imageCover = cover {
                coverImage.sd_setImage(with: URL.init(string: imageCover), placeholderImage: nil, options: [.handleCookies, .retryFailed], completed: nil)
            }
        }
    }
    var model: Author?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        contentView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longTap)))
        contentView.addSubview(coverImage)
    }
    
    @objc private func longTap() {
        let alert = UIAlertController(title: "", message: "Delete image", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
            if let cover = self.cover, let model = self.model {
                if let index = model.covers.index(of: cover) {
                    try! RealmManager.shared.realm.write {
                        model.covers.remove(at: index)
                        NotificationCenter.default.post(name: NSNotification.Name.init(kUDViewerReloadData), object: nil)
                    }
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    private lazy var coverImage = UIImageView().then {
        $0.frame = bounds
        $0.contentMode = .scaleAspectFill
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

