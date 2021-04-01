import UIKit
import RealmSwift
import SVProgressHUD
import Kingfisher

//缓存gdata
var cachedGdatas = [String: GData]()
private var checkingDoujinshi = [Int]()

class ListVC: BaseViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    private(set) lazy var searchController: UISearchController = {
        return UISearchController(searchResultsController: historyVC)
    }()
    private lazy var historyVC: SearchHistoryVC = {
        return self.storyboard!.instantiateViewController(withIdentifier: "SearchHistoryVC") as! SearchHistoryVC
    }()
    private var items: [Doujinshi] = []
    private var currentPage = -1
    private var loadingPage = -1
    private var pageCount = 0
    private var backGesture: InteractiveBackGesture?
    private var rowCount: Int { return min(12, max(2, Int(floor(collectionView.bounds.width / Defaults.List.cellWidth)))) }
    @IBOutlet weak var loadingView: LoadingView!
    @IBOutlet weak var findPageButton: UIButton!
    @IBOutlet weak var authorButton: UIButton!
    
    enum Mode: String {
        case normal = "normal"
        case download = "download"
        case favorite = "favorites"
        case history = "history"
    }
    private var mode: Mode {
        let text = searchController.searchBar.text?.lowercased() ?? ""
        if text == Mode.download.rawValue {
            return .download
        } else if text == Mode.history.rawValue {
            return .history
        } else if text.contains("favorites") {
            return .favorite
        } else {
            return .normal
        }
    }
    private var favoriteCategory: Int? {
        guard mode == .favorite else { return nil }
        let text = searchController.searchBar.text?.lowercased() ?? ""
        return text == "favorites" ? -1 : Int(text.replacingOccurrences(of: "favorites", with: ""))
    }
    
    private var existedIds = [Int]()    //缓存已获取的画廊id
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: collectionView)
        }
        ImageDownloader.default.downloadTimeout = 30;
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(ges:)))
        longPressGesture.delaysTouchesBegan = true
        collectionView.addGestureRecognizer(longPressGesture)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(ges:)))
        collectionView.addGestureRecognizer(pinchGesture)
        
        searchController.delegate = self
        if navigationController?.viewControllers.count == 1 {
            searchController.searchBar.text = Defaults.List.lastSearchKeyword
        } else {
            Defaults.List.lastSearchKeyword = searchController.searchBar.text ?? ""
            backGesture = InteractiveBackGesture(viewController: self, toView: collectionView)
        }
        historyVC.searchController = searchController
        historyVC.selectBlock = {[unowned self] text in
            self.searchController.isActive = false
            self.searchController.searchBar.text = text
            self.reloadData()
        }
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.showsCancelButton = true
        searchController.searchBar.enablesReturnKeyAutomatically = false
        searchController.searchBar.tintColor = view.tintColor
        definesPresentationContext = true
        
        loadNextPage()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(settingChanged(notification:)), name: .settingChanged, object: nil)
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        view.layoutIfNeeded()
        collectionView.collectionViewLayout.invalidateLayout()
        findPageButton.isHidden = Defaults.List.isHidePageSkip
        authorButton.isHidden = !Defaults.List.isShowAuthorList
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if searchController.isActive {
            searchController.dismiss(animated: false, completion: nil)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let indexPath = collectionView.indexPathsForVisibleItems.first
        
        collectionView?.collectionViewLayout.invalidateLayout()
        coordinator.animate(alongsideTransition: { _ in
            if let indexPath = indexPath {
                self.collectionView!.scrollToItem(at: indexPath, at: .top, animated: true)
            }
        })
    }
    
    private var initCellWidth = Defaults.List.defaultCellWidth
    @objc func pinch(ges: UIPinchGestureRecognizer) {
        if ges.state == .began {
            initCellWidth = collectionView.visibleCells.first?.frame.size.width ?? Defaults.List.defaultCellWidth
        } else if ges.state == .changed {
            let scale = ges.scale - 1
            let dx = initCellWidth * scale
            let width = min(max(initCellWidth + dx, 80), view.bounds.width)
            if width != Defaults.List.cellWidth {
                Defaults.List.cellWidth = width
                collectionView.performBatchUpdates({
                    collectionView.collectionViewLayout.invalidateLayout() 
                }, completion: nil)
            }
        }
    }
    

    func loadNextPage() {
        if mode == .download {
            loadingView.hide()
            items = RealmManager.shared.downloaded.map { $0 }
            collectionView.reloadData()
        } else if mode == .history {
            loadingView.hide()
            items = RealmManager.shared.browsedDoujinshi
            collectionView.reloadData()
        } else {
            guard loadingPage != currentPage + 1 else {return}
            loadingPage = currentPage + 1
            if loadingPage == 0 { loadingView.show() }
            RequestManager.shared.getList(page: loadingPage, search: searchController.searchBar.text) {[weak self] books, pageCount  in
                guard let self = self else {return}
                self.pageCount = pageCount
                self.loadingView.hide()
                guard books.count > 0 else {return}
                let lastIndext = max(0, self.items.count - 1)
                let insertIndexPaths = books.enumerated().map { IndexPath(item: $0.offset + lastIndext, section: 0) }
                self.items += books
                self.collectionView.performBatchUpdates({
                    self.collectionView.insertItems(at: insertIndexPaths)
                }, completion: nil)
                self.currentPage += 1
                self.loadingPage = -1
            }
        }
    }

    func reloadData(pageIndex: Int = -1) {
        checkingDoujinshi.removeAll()   //清除正在获取gdata数据的id
        existedIds.removeAll()          //清楚已获取的id
        currentPage = pageIndex
        loadingPage = pageIndex
        let deleteIndexPaths = items.enumerated().map { IndexPath(item: $0.offset, section: 0)}
        items = []
        collectionView.performBatchUpdates({
            self.collectionView.deleteItems(at: deleteIndexPaths)
        }, completion: { _ in
            self.loadNextPage()
        })
    }
    
    private func prefetchGData(indexPaths: Array<IndexPath>) -> Void {
        for index in indexPaths {
            self.checkGData(indexPath: index, completeBlock: nil)
        }
    }
    
    private func checkGData(indexPath: IndexPath, completeBlock block: (() -> Void)?) {
        let index = indexPath.item
        guard items.count >= index, !checkingDoujinshi.contains(items[index].id) else { return }
        
        if items[index].isDownloaded || items[index].gdata != nil {
            return
        } else {
            
            let doujinshi = items[index]
            
            //Temp cover
            doujinshi.pages.removeAll()
            if !doujinshi.coverUrl.isEmpty {
                let coverPage = Page()
                coverPage.thumbUrl = doujinshi.coverUrl
                doujinshi.pages.append(coverPage)
            }
            
            if let gdata = cachedGdatas["\(doujinshi.id)"] {
                doujinshi.gdata = gdata
                block?()
                return
            }
            //保存需要请求的id
            checkingDoujinshi.append(doujinshi.id)
            
            RequestManager.shared.getGData(doujinshi: doujinshi) { [weak self] gdata in
                
                //网络请求有延迟，如果当前页面快速切换，需要判断当前画廊是否还存在
                guard let gdata = gdata else { return }
                cachedGdatas["\(doujinshi.id)"] = gdata  //缓存 gdata
                guard let self = self,
                    self.items.count >= index,
                    doujinshi.id == self.items[index].id,
                    checkingDoujinshi.contains(doujinshi.id)
                    else { return }
                
                doujinshi.gdata = gdata
                //删除已请求的id
                let temp = checkingDoujinshi.filter { return $0 != doujinshi.id }
                checkingDoujinshi = temp
                block?()
            }
        }
    }
    
    @IBAction func setPage(_ sender: Any) {
        let controller = UIAlertController(title: "skip", message: "total \(self.pageCount - 1)", preferredStyle: .alert)
        controller.addTextField {[weak self] (textFeild) in
            textFeild.placeholder = "page number"
            textFeild.text = "\(self?.currentPage ?? 1)"
            textFeild.keyboardType = .numberPad
        }
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        controller.addAction(UIAlertAction(title: "Sure", style: .default, handler: {[weak self] (_) in
            if let pageStr = controller.textFields?.first?.text, let page = Int(pageStr) {
                self?.reloadData(pageIndex: page - 1)
            }
        }))
        controller.addAction(UIAlertAction(title: "Reset", style: .default, handler: {[weak self] (_) in
            self?.reloadData()
        }))
        present(controller, animated: true, completion: nil)
    }
    

    @IBAction func showFavorites(sender: UIBarButtonItem) {
        guard navigationController?.presentedViewController == nil else {return}
        if Defaults.List.isShowFavoriteList {
            let sheet = UIAlertController(title: "Favorites", message: nil, preferredStyle: .actionSheet)
            let all = UIAlertAction(title: "ALL", style: .default, handler: { (_) in
                self.showSearch(with: "favorites")
                Defaults.List.lastSearchKeyword = self.searchController.searchBar.text ?? ""
            })
            sheet.addAction(all)
            Defaults.List.favoriteTitles.enumerated().forEach { f in
                let a = UIAlertAction(title: f.element, style: .default, handler: { (_) in
                    self.showSearch(with: "favorites\(f.offset)")
                    Defaults.List.lastSearchKeyword = self.searchController.searchBar.text ?? ""
                })
                sheet.addAction(a)
            }
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            sheet.popoverPresentationController?.barButtonItem = sender
            present(sheet, animated: true, completion: nil)
        } else {
            showSearch(with: "favorites")
            Defaults.List.lastSearchKeyword = searchController.searchBar.text ?? ""
        } 
    }
    
    @IBAction func showDownloads() {
        guard navigationController?.presentedViewController == nil else {return}
        showSearch(with: "download")
        Defaults.List.lastSearchKeyword = searchController.searchBar.text ?? ""
    }
    
    @IBAction func navigateToAuthor(_ sender: Any) {
        let authorVC = AuthorVC.shareInstance
        authorVC.selectHandler = {[weak self] author in
            self?.schemeOpen(q: author)
        }
        navigationController?.pushViewController(authorVC, animated: true)
    }
    
    func showSearch(with shotcut: String) {
        searchController.searchBar.text = shotcut
        if searchController.isActive {
            searchController.dismiss(animated: false, completion: nil)
        }
        reloadData()
    }

    @objc func longPress(ges: UILongPressGestureRecognizer) {
        
        guard ges.state == .began, let indexPath = collectionView.indexPathForItem(at: ges.location(in: collectionView)) else {return}

        let doujinshi = items[indexPath.item]
        let title = mode == .download ? "Delete" : "Action"
        let actionTitle = mode == .download ? "Delete" : "Remove"
        guard mode == .download || mode == .favorite else {
            if Defaults.List.isShowAuthorList {
                let addAlert = UIAlertController(title: "AddToAuthor", message: nil, preferredStyle: .alert)
                addAlert.addTextField {(textFeild) in
                    textFeild.text = doujinshi.author.lowercased()
                }
                addAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                addAlert.addAction(UIAlertAction(title: "Sure", style: .default, handler: {(_) in
                    if let text = addAlert.textFields?.first?.text {
                        if let doujinshiString = doujinshi.toJSONString(), let newModel = Doujinshi.deserialize(from: doujinshiString) {
                            newModel.title = "[\(text)]"
                            RealmManager.shared.saveAuthor(doujinshi: newModel)
                        }
                    }
                }))
                present(addAlert, animated: true, completion: nil)

            }
            return
        }
        
        let alert = UIAlertController(title: title, message: doujinshi.title, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: actionTitle, style: .destructive) { _ in
            if self.mode == .download {
                DownloadManager.shared.deleteDownloaded(doujinshi: doujinshi)
                self.items = RealmManager.shared.downloaded.map { $0 }
                self.collectionView.performBatchUpdates({
                    self.collectionView.deleteItems(at: [indexPath])
                }, completion: nil)
            } else if self.mode == .favorite {
                RequestManager.shared.deleteFavorite(doujinshi: doujinshi)
                self.items.remove(at: indexPath.item)
                self.collectionView.performBatchUpdates({
                    self.collectionView.deleteItems(at: [indexPath])
                }, completion: nil)
            }
        }
        if mode == .favorite {
            let moveAction = UIAlertAction(title: "Move", style: .default) { (_) in
                self.showFavoriteMoveSheet(with: indexPath)
            }
            alert.addAction(moveAction)
        }
        if mode == .download {
            let cell = collectionView.cellForItem(at: indexPath)!
            let vc = UIActivityViewController(activityItems: doujinshi.pages.map { $0.localUrl }, applicationActivities: nil)
            vc.popoverPresentationController?.sourceView = collectionView
            vc.popoverPresentationController?.sourceRect = cell.frame
            let shareAction = UIAlertAction(title: "Share", style: .default) { (_) in
                self.present(vc, animated: true, completion: nil)
            }
            alert.addAction(shareAction)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func showFavoriteMoveSheet(with indexPath: IndexPath) {
        let doujinshi = items[indexPath.item]
        let sheet = UIAlertController(title: "Move to", message: doujinshi.title, preferredStyle: .actionSheet)
        let displayingFavCategory = favoriteCategory ?? -1
        Defaults.List.favoriteTitles.enumerated().forEach { f in
            if displayingFavCategory != f.offset {
                let a = UIAlertAction(title: f.element, style: .default, handler: { (_) in
                    RequestManager.shared.moveFavorite(doujinshi: doujinshi, to: f.offset)
                    if displayingFavCategory != -1 {
                        self.items.remove(at: indexPath.item)
                        self.collectionView.performBatchUpdates({
                            self.collectionView.deleteItems(at: [indexPath])
                        }, completion: nil)
                    } else {
                        SVProgressHUD.show("→".toIcon(), status: nil)
                        SVProgressHUD.dismiss(withDelay: 1)
                    }
                })
                sheet.addAction(a)
            }
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        let sourceView = collectionView.cellForItem(at: indexPath)
        sheet.popoverPresentationController?.sourceView = sourceView
        sheet.popoverPresentationController?.sourceRect = CGRect(x: 0, y: sourceView!.bounds.height/2, width: sourceView!.bounds.width, height: 0)
        present(sheet, animated: true, completion: nil)
    }
    
    @objc func settingChanged(notification: Notification) {
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        findPageButton.isHidden = Defaults.List.isHidePageSkip
        authorButton.isHidden = !Defaults.List.isShowAuthorList
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: self)
        if segue.identifier == "showSetting" {
        }
    }
}

extension ListVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let doujinshi = items[indexPath.item]
        let cell = cell as! ListCell
        
        if doujinshi.isDownloaded, let image = UIImage(contentsOfFile: documentURL.appendingPathComponent(doujinshi.coverUrl).path) {
            cell.imageView.image = image
            cell.loadingView?.hide(animated: false)
        }else {
            cell.imageView.kf.setImage(with: URL(string: doujinshi.coverUrl), options: [.transition(ImageTransition.fade(0.8)), .requestModifier(ImageManager.shared.modifier),.processor(ListCell.downProcessor),.cacheOriginalImage])
        }
        
        checkGData(indexPath: indexPath) { [weak cell] in
            guard let c = cell, c.tag == doujinshi.id else { return }
            c.configCellItem(doujinshi: doujinshi)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ListCell
        
        let doujinshi = items[indexPath.item]
        cell.imageView.hero.id = "image_\(doujinshi.id)_0"
        cell.imageView.hero.modifiers = [.arc(intensity: 1), .forceNonFade]
        cell.imageView.contentMode = .scaleAspectFill
        cell.imageView.kf.indicatorType = .activity
        cell.tag = doujinshi.id
        
        cell.containerView.hero.modifiers = [.arc(intensity: 1), .fade, .source(heroID: "image_\(doujinshi.id)_0")]
        
        cell.pageCountLabel.layer.cornerRadius = cell.pageCountLabel.bounds.height/2
        
        if let language = doujinshi.title.language {
            cell.languageLabel.isHidden = Defaults.List.isHideTag
            cell.languageLabel.text = language.capitalized
            cell.languageLabel.layer.cornerRadius = cell.languageLabel.bounds.height/2
        } else {
            cell.languageLabel.isHidden = true
        }

        if let convent = doujinshi.title.conventionName {
            cell.conventionLabel.isHidden = Defaults.List.isHideTag
            cell.conventionLabel.text = convent
            cell.conventionLabel.layer.cornerRadius = cell.conventionLabel.bounds.height/2
        } else {
            cell.conventionLabel.isHidden = true
        }
        cell.configCellItem(doujinshi: doujinshi)
        cell.titleLabel?.text = doujinshi.title
        cell.titleLabel?.isHidden = Defaults.List.isHideTitle
        
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard mode != .download, items.count > 0 else {return}
        
        let tempItems = indexPaths.map { $0.item }
        let exceed = tempItems.filter { return $0 >= items.count }.count > 0
        guard !exceed else { return }
        
        let urls = indexPaths.map { URL(string: self.items[$0.item].coverUrl)! }
        ImageManager.shared.prefetch(urls: urls)
        self.prefetchGData(indexPaths: indexPaths)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "GalleryVC") as! GalleryVC
        let item = items[indexPath.item]
        vc.doujinshi = item
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! ListCell
        cell.imageView.kf.cancelDownloadTask()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let width = (collectionView.bounds.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right - flowLayout.minimumInteritemSpacing * CGFloat((rowCount - 1))) / CGFloat(rowCount)
        return CGSize(width: width, height: width * paperRatio)
    }
    
    
}

extension ListVC: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView.indexPathForItem(at: location) else {return nil}
        let vc = storyboard!.instantiateViewController(withIdentifier: "GalleryVC") as! GalleryVC
        let item = items[indexPath.item]
        vc.doujinshi = item
        if mode == .favorite {
            vc.doujinshi.isFavorite = true 
        }
        vc.delegate = self
        return vc
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
}

extension ListVC: GalleryVCPreviewActionDelegate {
    
    func galleryDidSelectTag(text: String) {
        pushToListVC(with: text)
    }
    
    func pushToListVC(with tag: String) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "ListVC") as! ListVC
        vc.searchController.searchBar.text = tag
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ListVC: UISearchBarDelegate, UISearchControllerDelegate {
    
    func schemeOpen(q: String) {
        searchController.searchBar.text = q
        reloadData()
        RealmManager.shared.saveSearchHistory(text: q)
        Defaults.List.lastSearchKeyword = searchController.searchBar.text ?? ""
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = true }
        searchController.dismiss(animated: true, completion: nil)
        reloadData()
        RealmManager.shared.saveSearchHistory(text: searchBar.text)
        Defaults.List.lastSearchKeyword = searchController.searchBar.text ?? ""
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        DispatchQueue.main.async {
            self.searchController.searchResultsController?.view.isHidden = false
        }
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = false }
        DispatchQueue.main.async {
            searchController.searchResultsController?.view.isHidden = false
        }
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchResultsController?.view.isHidden = false
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = true }
        Defaults.List.lastSearchKeyword = searchController.searchBar.text ?? ""
    }
}

extension ListVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        switch mode {
        case .favorite, .normal:
            if let indexPath = collectionView.indexPathsForVisibleItems.sorted().last,
                indexPath.item > items.count - max(rowCount * 2, 10) {
                loadNextPage()
            }
        default:
            break
        }
        
    }
} 
