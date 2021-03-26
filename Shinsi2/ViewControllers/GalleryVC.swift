import UIKit
import Hero
import Kingfisher
import SVProgressHUD
import SafariServices

class GalleryVC: BaseViewController {
    var doujinshi: Doujinshi!
    private var browsingHistory: BrowsingHistory?
    private var didScrollToHistory = false
    private var currentPage = 0
    private var backGesture: InteractiveBackGesture!
    private var isPartDownloading = false { didSet { handlePartDownload() } }
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tagButton: UIBarButtonItem!
    @IBOutlet weak var downloadButton: UIBarButtonItem!
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBOutlet weak var commentButton: UIBarButtonItem!
    @IBOutlet weak var appendWhitePageButton: UIBarButtonItem!
    @IBOutlet weak var loadingView: LoadingView!
    private var scrollBar: QuickScrollBar!
    weak var delegate: GalleryVCPreviewActionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = doujinshi.gdata?.getTitle() ?? doujinshi.title
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        browsingHistory = RealmManager.shared.browsingHistory(for: doujinshi)
        if browsingHistory == nil {
            RealmManager.shared.createBrowsingHistory(for: doujinshi)
            browsingHistory = RealmManager.shared.browsingHistory(for: doujinshi)
        }
        
        backGesture = InteractiveBackGesture(viewController: self, toView: collectionView)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(ges:)))
        collectionView.addGestureRecognizer(pinchGesture)
        
        tagButton.isEnabled = false
        downloadButton.isEnabled = false
        favoriteButton.isEnabled = false
        commentButton.isEnabled = false
        appendWhitePageButton.image = Defaults.Gallery.isAppendBlankPage ? #imageLiteral(resourceName: "ic_page_1") : #imageLiteral(resourceName: "ic_page_0")
        
        if !isSizeClassRegular {
            navigationItem.rightBarButtonItems =
                navigationItem.rightBarButtonItems?.filter({$0 != appendWhitePageButton})
        }
    
        if Defaults.Gallery.isShowQuickScroll {
            scrollBar = QuickScrollBar(scrollView: collectionView, target: self)
            scrollBar.textForIndexPath = { indexPath in
                return "\(indexPath.item + 1)"
            }
            scrollBar.color = UIColor.init(white: 0.2, alpha: 0.6)
            scrollBar.gestureRecognizeWidth = 44
            let width: CGFloat = 38
            scrollBar.indicatorRightMargin = -width/2
            scrollBar.indicatorCornerRadius = width/2
            scrollBar.indicatorSize = CGSize(width: width + 6, height: width)
            scrollBar.isBarHidden = true
            scrollBar.textOffset = 10
            scrollBar.draggingTextOffset = 40
        }
        
        checkGData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard UIApplication.shared.applicationState == .active else {return}
        let indexPath = collectionView.indexPathsForVisibleItems.first
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
        coordinator.animate(alongsideTransition: { _ in
            if let indexPath = indexPath {
                self.collectionView!.scrollToItem(at: indexPath, at: .top, animated: false)
            }
        })
    }
    
    private var initCellWidth = Defaults.Gallery.defaultCellWidth
    @objc func pinch(ges: UIPinchGestureRecognizer) {
        if ges.state == .began {
            initCellWidth = collectionView.visibleCells.first?.frame.size.width ?? Defaults.Gallery.defaultCellWidth
        } else if ges.state == .changed {
            let scale = ges.scale - 1
            let dx = initCellWidth * scale
            let width = min(max(initCellWidth + dx, 80), view.bounds.width)
            if width != Defaults.Gallery.cellWidth {
                Defaults.Gallery.cellWidth = width
                collectionView.performBatchUpdates({
                    collectionView.collectionViewLayout.invalidateLayout()
                }, completion: nil)
            }
        }
    }
    
    private func checkGData() {
        updateNavigationItems()
        if doujinshi.isDownloaded, doujinshi.gdata != nil {
            loadingView.hide()
            scrollToLastReadingPage()
        } else if let gdata = doujinshi.gdata, doujinshi.pages.count == gdata.filecount {
            loadingView.hide()
            scrollToLastReadingPage()
        } else if doujinshi.gdata != nil, doujinshi.pages.count > 0, let perPageCount = doujinshi.perPageCount {
            loadingView.hide()
            scrollToLastReadingPage()
            currentPage = doujinshi.pages.count / perPageCount
            loadPages()
        } else {
            //Temp cover
            doujinshi.pages.removeAll()
            if !doujinshi.coverUrl.isEmpty {
                let coverPage = Page()
                coverPage.thumbUrl = doujinshi.coverUrl
                doujinshi.pages.append(coverPage)
            }
            loadingView.show()
            RequestManager.shared.getGData(doujinshi: self.doujinshi) { [weak self] gdata in
                guard let gdata = gdata, let self = self else { return }
                self.loadingView.hide()
                self.doujinshi.pages.removeAll()
                self.doujinshi.gdata = gdata
                self.updateNavigationItems()
                self.loadPages()
            }
        }
    }
    
    func updateNavigationItems() {
        tagButton.isEnabled = doujinshi.gdata != nil
        downloadButton.isEnabled = doujinshi.canDownload
        commentButton.isEnabled = doujinshi.comments.count > 0
        favoriteButton.isEnabled = !doujinshi.isFavorite && doujinshi.pages.count > 1
        title = doujinshi.gdata?.getTitle() ?? doujinshi.title
    }
    
    func loadPages() {
        RequestManager.shared.getDoujinshi(doujinshi: doujinshi, at: currentPage) { [weak self] pages in
            guard let self = self, pages.count > 0 else { return }
            self.favoriteButton.isEnabled = !self.doujinshi.isFavorite
            self.commentButton.isEnabled = self.doujinshi.comments.count > 0
            let isTempCover = self.doujinshi.pages.count == 0 && self.collectionView.numberOfItems(inSection: 0) == 1
            self.doujinshi.pages.append(objectsIn: pages)
            var new = pages.map({IndexPath(item: self.doujinshi.pages.index(of: $0)!, section: 0)})
            if isTempCover {
                new.remove(at: 0)
                ImageManager.shared.prefetch(urls: [URL(string: pages.first!.thumbUrl)!])
            }
            self.collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: new)
            }, completion: nil)
            
            if self.doujinshi.pages.count < self.doujinshi.gdata!.filecount {
                self.currentPage += 1
                self.loadPages()
            } else {
                // All pages feteched
                self.downloadButton.isEnabled = !RealmManager.shared.isDounjinshiDownloaded(doujinshi: self.doujinshi)
            }
            self.scrollToLastReadingPage()
        }
    }
    
    private func scrollToLastReadingPage() {
        guard Defaults.Gallery.isAutomaticallyScrollToHistory else {return}
        guard let readingPage = browsingHistory?.currentPage,
            readingPage < doujinshi.pages.count,
            didScrollToHistory == false else { return }
        didScrollToHistory = true
        // Scroll after collectionView loaded
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: IndexPath(row: readingPage, section: 0), at: .top, animated: true)
        }
    }
    
    @IBAction func addToFavorite(sender: UIBarButtonItem) {
        guard navigationController?.presentedViewController == nil else {return}
        if Defaults.Gallery.isShowFavoriteList {
            let sheet = UIAlertController(title: "Favorites", message: nil, preferredStyle: .actionSheet)
            Defaults.List.favoriteTitles.enumerated().forEach({ f in
                let a = UIAlertAction(title: f.element, style: .default, handler: { (_) in
                    self.favoriteButton.isEnabled = false
                    RequestManager.shared.addDoujinshiToFavorite(doujinshi: self.doujinshi, category: f.offset)
                    SVProgressHUD.show("♥".toIcon(), status: nil)
                })
                sheet.addAction(a)
            })
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            sheet.popoverPresentationController?.barButtonItem = sender
            present(sheet, animated: true, completion: nil)
        } else {
            favoriteButton.isEnabled = false
            RequestManager.shared.addDoujinshiToFavorite(doujinshi: doujinshi)
            SVProgressHUD.show("♥".toIcon(), status: nil)
        }
    }
    
    @IBAction func downloadButtonDidClick(_ sender: UIBarButtonItem) {
        guard navigationController?.presentedViewController == nil else {return}
        if isPartDownloading {
            downloadSelectedPage()
        } else {
            let sheet = UIAlertController(title: "Download", message: nil, preferredStyle: .actionSheet)
            let downloadAll = UIAlertAction(title: "All", style: .default) { (_) in
                self.downloadAll()
            }
            let downloadPart = UIAlertAction(title: "Part", style: .default) { (_) in
                self.isPartDownloading = true
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            sheet.addAction(downloadAll)
            sheet.addAction(downloadPart)
            sheet.addAction(cancel)
            sheet.popoverPresentationController?.sourceView = view
            sheet.popoverPresentationController?.barButtonItem = sender
            navigationController?.present(sheet, animated: true, completion: nil)
        }
    }
    
    @IBAction func appendBlankPageButtonDidClick(_ sender: UIBarButtonItem) {
        guard navigationController?.presentedViewController == nil else {return}
        Defaults.Gallery.isAppendBlankPage.toggle()
        sender.image = Defaults.Gallery.isAppendBlankPage ? #imageLiteral(resourceName: "ic_page_1") : #imageLiteral(resourceName: "ic_page_0")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "showTag",
            let nv = segue.destination as? UINavigationController,
            let vc = nv.viewControllers.first as? TagVC {
            vc.doujinshi = doujinshi
            vc.clickBlock = { [unowned self, unowned vc] tag in
                vc.dismiss(animated: true, completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
                        self.pushToListVC(with: tag)
                    })
                })
            }
        }
        if segue.identifier == "showComment",
            let nv = segue.destination as? UINavigationController,
            let vc = nv.viewControllers.first as? CommentVC {
            vc.doujinshi = doujinshi
            vc.delegate = self
        }
    }
    
    func pushToListVC(with tag: String) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "ListVC") as! ListVC
        vc.searchController.searchBar.text = tag
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func handlePartDownload() {
        setEditing(isPartDownloading, animated: true)
        navigationItem.rightBarButtonItems?
            .filter({ $0 != downloadButton })
            .forEach({ $0.isEnabled = !isPartDownloading })
        navigationItem.leftBarButtonItem = isPartDownloading ?
            UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelPartDownload(sender:)))
            : nil
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if !isPartDownloading,
            let selecteds = collectionView.indexPathsForSelectedItems,
            selecteds.count != 0 {
            selecteds.forEach({collectionView.deselectItem(at: $0, animated: animated)})
        }
        collectionView.allowsMultipleSelection = isPartDownloading
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }
    
    @objc func cancelPartDownload(sender: UIBarButtonItem) {
        isPartDownloading = false
    }
    
    func downloadAll() {
        downloadButton.isEnabled = false
        DownloadManager.shared.download(doujinshi: doujinshi)
        DownloadBubble.shared.show(on: navigationController!)
    }
    
    func downloadSelectedPage() {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems?.sorted(),
            selectedIndexPaths.count > 0
            else {
                isPartDownloading = false
                return
        }
        let new = Doujinshi(value: doujinshi!)
        new.gdata = GData(value: doujinshi.gdata!)
        new.pages.removeAll()
        for i in selectedIndexPaths {
            new.pages.append(Page(value: doujinshi.pages[i.item]))
        }
        new.gdata!.gid = new.gdata!.gid + String(Date().timeIntervalSince1970)
        new.gdata!.filecount = selectedIndexPaths.count
        new.coverUrl = new.pages.first!.thumbUrl
        DownloadManager.shared.download(doujinshi: new)
        DownloadBubble.shared.show(on: navigationController!)
        
        isPartDownloading = false
    }
    
    override var previewActionItems: [UIPreviewActionItem] { 
        var actions: [UIPreviewActionItem] = []
        let artist = doujinshi.title.artist
        if let artist = artist {
            actions.append( UIPreviewAction(title: "Artist: \(artist)", style: .default) { (_, _) -> Void in
                self.delegate?.galleryDidSelectTag(text: "\(artist)" )
            })
        }
        if let circle = doujinshi.title.circleName, circle != artist {
            actions.append( UIPreviewAction(title: "Circle: \(circle)", style: .default) { (_, _) -> Void in
                self.delegate?.galleryDidSelectTag(text: "\(circle)" )
            })
        }
        if !doujinshi.isDownloaded && !doujinshi.isFavorite {
            actions.append( UIPreviewAction(title: "♥", style: .default) { (_, _) -> Void in 
                RequestManager.shared.addDoujinshiToFavorite(doujinshi: self.doujinshi)
                SVProgressHUD.show("♥".toIcon(), status: nil)
            })
        }
        return actions
    }
}

extension GalleryVC: CommentVCDelegate {
    func commentVC(_ vc: CommentVC, didTap url: URL) {
        if url.absoluteString.contains(Defaults.URL.host) {
            if url.absoluteString.contains(Defaults.URL.host+"/g/"), url.absoluteString != doujinshi.url {
                //Gallery
                vc.dismiss(animated: true) {
                    let d = Doujinshi(value: ["url": url.absoluteString])
                    let vc = self.storyboard!.instantiateViewController(withIdentifier: "GalleryVC") as! GalleryVC
                    vc.doujinshi = d
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else if url.absoluteString.contains(Defaults.URL.host+"/s/") {
                //Page
                if let page = doujinshi.pages.filter({ $0.url == url.absoluteString }).first,
                    let index = doujinshi.pages.index(of: page) {
                    vc.dismiss(animated: true) {
                        self.collectionView.scrollToItem(at: IndexPath(item: index, section: 0),
                                                         at: .top,
                                                         animated: false)
                    }
                }
            } else {
                vc.dismiss(animated: true) {
                    let webVC = self.storyboard?.instantiateViewController(withIdentifier: "WebVC") as! WebVC
                    webVC.url = url
                    let nvc = UINavigationController(rootViewController: webVC)
                    self.navigationController?.present(nvc, animated: true, completion: nil)
                }
            }
        } else {
            vc.dismiss(animated: true) {
                let sfVC = SFSafariViewController(url: url)
                self.navigationController?.present(sfVC, animated: true, completion: nil)
            }
        }
    }
}

protocol GalleryVCPreviewActionDelegate: class {
    func galleryDidSelectTag(text: String)
}

extension GalleryVC: UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return doujinshi.pages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageCell
        let page = doujinshi.pages[indexPath.item]
        if doujinshi.isDownloaded {
            if page.localImage != nil {
                cell.imageView.image = page.localImage
                cell.loadingView?.hide(animated: false)
            }else {
                cell.imageView.kf.setImage(with: URL(string: page.thumbUrl), placeholder: nil, options: [.transition(ImageTransition.fade(0.2))], progressBlock: nil) { (result) in
                    switch result {
                    case .success(_):
                        cell.loadingView?.hide(animated: false)
                    case .failure(_) :
                        cell.loadingView?.show(animated: false)
                    }
                }
            }
        } else {
            if let image = ImageManager.shared.getCache(forKey: page.url) {
                cell.imageView.image = image
                cell.loadingView?.hide(animated: false)
            } else {
                cell.imageView.kf.setImage(with: URL(string: page.thumbUrl), placeholder: nil, options: [.transition(ImageTransition.fade(0.2))], progressBlock: nil) { (result) in
                    switch result {
                    case .success(_):
                        cell.loadingView?.hide(animated: false)
                    case .failure(_) :
                        cell.loadingView?.show(animated: false)
                    }
                }
            }
        }
        cell.imageView.hero.id = "image_\(doujinshi.id)_\(indexPath.item)"
        cell.imageView.hero.modifiers = [.arc(intensity: 1)]
        cell.imageView.alpha = isPartDownloading ? (isIndexPathSelected(indexPath: indexPath) ? 1 : 0.5) : 1
        
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        return cell
    }
    
    func isIndexPathSelected(indexPath: IndexPath) -> Bool {
        if let selecteds = collectionView.indexPathsForSelectedItems {
            return selecteds.contains(indexPath)
        }
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard !doujinshi.isDownloaded else {return}
        let urls = indexPaths.map({URL(string: doujinshi.pages[$0.item].thumbUrl)!})
        ImageManager.shared.prefetch(urls: urls)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !isPartDownloading {
            guard doujinshi.pages.count > 1 else {return}
            let vc = storyboard!.instantiateViewController(withIdentifier: "ViewerVC") as! ViewerVC
            vc.selectedIndexPath = indexPath
            vc.doujinshi = doujinshi
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        } else {
            let c = collectionView.cellForItem(at: indexPath) as! ImageCell
            c.imageView.alpha = 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if isPartDownloading {
            let c = collectionView.cellForItem(at: indexPath) as! ImageCell
            c.imageView.alpha = 0.5
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let rows = max(2, floor(collectionView.bounds.width / Defaults.Gallery.cellWidth))
        let width = (collectionView.bounds.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right - flowLayout.minimumInteritemSpacing * (rows - 1)) / rows
        return CGSize(width: width, height: width * paperRatio)
    }
}

extension GalleryVC: HeroViewControllerDelegate {
    func heroWillStartAnimatingFrom(viewController: UIViewController) {
        if let vc = viewController as? ViewerVC, var originalCellIndex = vc.selectedIndexPath, var currentCellIndex = vc.collectionView?.indexPathsForVisibleItems.first {
            view.hero.modifiers = nil
            originalCellIndex = IndexPath(item: min(originalCellIndex.item - (Defaults.Gallery.isAppendBlankPage ? 1 : 0), doujinshi.pages.count - 1), section: originalCellIndex.section)
            currentCellIndex = IndexPath(item: min(currentCellIndex.item - (Defaults.Gallery.isAppendBlankPage ? 1 : 0), doujinshi.pages.count - 1), section: currentCellIndex.section)
            if !collectionView.indexPathsForVisibleItems.contains(currentCellIndex) {
                collectionView.scrollToItem(at: currentCellIndex, at: originalCellIndex < currentCellIndex ? .bottom : .top, animated: false)
            }
        }
    }
    
    func heroDidEndAnimatingFrom(viewController: UIViewController) {
        if viewController is ViewerVC {
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        }
    }
}
