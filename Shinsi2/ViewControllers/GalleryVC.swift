import UIKit
import Hero
import SDWebImage
import SVProgressHUD

class GalleryVC: BaseViewController {
    weak var doujinshi : Doujinshi!
    private var currentPage = 0
    private var backGesture: InteractiveBackGesture!
    private var isPartDownloading = false {
        didSet {
            setEditing(isPartDownloading, animated: true)
            navigationItem.rightBarButtonItems?.filter{ $0 != downloadButton }.forEach{ $0.isEnabled = !isPartDownloading }
        }
    }
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
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        backGesture = InteractiveBackGesture(viewController: self, toView: collectionView)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(ges:)))
        collectionView.addGestureRecognizer(pinchGesture)
        
        tagButton.isEnabled = false
        downloadButton.isEnabled = false
        favoriteButton.isEnabled = false
        commentButton.isEnabled = false
        appendWhitePageButton.image = Defaults.Gallery.isAppendWhitePage ? #imageLiteral(resourceName: "ic_page_1") : #imageLiteral(resourceName: "ic_page_0")
        if UIDevice.current.userInterfaceIdiom != .pad {
            navigationItem.rightBarButtonItems = navigationItem.rightBarButtonItems?.filter{ $0 != appendWhitePageButton}
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
        
        getGData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard UIApplication.shared.applicationState == .active else {return}
        let indexPath = collectionView.indexPathsForVisibleItems.first
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
        coordinator.animate(alongsideTransition: {ctx in
            if let indexPath = indexPath {
                self.collectionView!.scrollToItem(at: indexPath, at:.top, animated: false)
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
    
    func getGData() {
        if doujinshi.isDownloaded , let gdata = doujinshi.gdata {
            loadingView.hide()
            tagButton.isEnabled = true
            downloadButton.isEnabled = false
            commentButton.isEnabled = doujinshi.comments.count > 0
            favoriteButton.isEnabled = !doujinshi.isFavorite
            title = gdata.getTitle()
            collectionView.reloadData()
        } else if let gdata = doujinshi.gdata , doujinshi.pages.count == gdata.filecount {
            loadingView.hide()
            tagButton.isEnabled = true
            downloadButton.isEnabled = true
            commentButton.isEnabled = doujinshi.comments.count > 0
            favoriteButton.isEnabled = !doujinshi.isFavorite
            title = gdata.getTitle()
            collectionView.reloadData()
        } else if let gdata = doujinshi.gdata, doujinshi.pages.count > 0 {
            loadingView.hide()
            tagButton.isEnabled = true
            title = gdata.getTitle()
            currentPage = doujinshi.pages.count / 20
            loadPages()
        } else {
            //Temp cover
            let coverPage = Page()
            coverPage.thumbUrl = doujinshi.coverUrl
            doujinshi.pages.append(coverPage)
            
            loadingView.show()
            RequestManager.shared.getGData(doujinshi: self.doujinshi) { [weak self] gdata in
                guard let gdata = gdata , let self = self else { return }
                self.loadingView.hide()
                self.tagButton.isEnabled = true
                self.title = gdata.getTitle()
                self.doujinshi.gdata = gdata
                self.doujinshi.pages.removeAll()
                self.loadPages()
            }
        }
    }
    
    func loadPages() {
        RequestManager.shared.getDoujinshi(doujinshi: doujinshi, at: currentPage) { [weak self] pages in
            guard let self = self, pages.count > 0 else { return }
            self.favoriteButton.isEnabled = !self.doujinshi.isFavorite
            self.commentButton.isEnabled = self.doujinshi.comments.count > 0
            let isTempCover = self.doujinshi.pages.count == 0 && self.collectionView.numberOfItems(inSection: 0) == 1
            self.doujinshi.pages.append(objectsIn: pages)
            var new = pages.map{ IndexPath(item: self.doujinshi.pages.index(of: $0)!, section: 0) }
            if isTempCover {
                new.remove(at: 0)
                ImageManager.shared.prefetch(urls: [URL(string:pages.first!.thumbUrl)!])
            }
            self.collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: new)
            }, completion: nil)
            
            if self.doujinshi.pages.count < self.doujinshi.gdata!.filecount {
                self.currentPage += 1
                self.loadPages()
            } else {
                self.downloadButton.isEnabled = !RealmManager.shared.isDounjinshiDownloaded(doujinshi: self.doujinshi)
            }
        }
    }
    
    @IBAction func addToFavorite() {
        guard navigationController?.presentedViewController == nil else {return}
        favoriteButton.isEnabled = false
        RequestManager.shared.addDoujinshiToFavorite(doujinshi: doujinshi)
        SVProgressHUD.show("♥".toIcon(), status: nil)
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
    
    @IBAction func appendWhitePageButtonDidClick(_ sender: UIBarButtonItem) {
        guard navigationController?.presentedViewController == nil else {return}
        Defaults.Gallery.isAppendWhitePage.toggle()
        sender.image = Defaults.Gallery.isAppendWhitePage ? #imageLiteral(resourceName: "ic_page_1") : #imageLiteral(resourceName: "ic_page_0")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "showPopover", let nv = segue.destination as? UINavigationController, let vc = nv.viewControllers.first as? TagVC {
            vc.doujinshi = doujinshi
            vc.clickBlock = {[unowned self,unowned vc] tag in
                vc.dismiss(animated: true, completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 , execute: {
                        self.pushToListVC(with: tag)
                    })
                })
            }
        }
        
        if segue.identifier == "showComment",  let nv = segue.destination as? UINavigationController, let vc = nv.viewControllers.first as? CommentVC {
            vc.comments = doujinshi.comments 
        }
    }
    
    func pushToListVC(with tag: String) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "ListVC") as! ListVC
        vc.searchController.searchBar.text = tag
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if !isPartDownloading, let selecteds = collectionView.indexPathsForSelectedItems , selecteds.count != 0  {
            selecteds.forEach{collectionView.deselectItem(at: $0, animated: animated)}
        }
        collectionView.allowsMultipleSelection = isPartDownloading
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }
    
    func downloadAll() {
        downloadButton.isEnabled = false
        DownloadManager.shared.download(doujinshi: doujinshi)
        DownloadBubble.shared.show(on:navigationController!)
    }
    
    func downloadSelectedPage() {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems?.sorted(), selectedIndexPaths.count > 0 else { isPartDownloading = false;  return}
        let new = Doujinshi(value:doujinshi)
        new.gdata = GData(value:doujinshi.gdata!)
        new.pages.removeAll()
        for i in selectedIndexPaths {
            new.pages.append(Page(value:doujinshi.pages[i.item]))
        }
        new.gdata!.gid = new.gdata!.gid + String(Date().timeIntervalSince1970)
        new.gdata!.filecount = selectedIndexPaths.count
        new.coverUrl = new.pages.first!.thumbUrl
        DownloadManager.shared.download(doujinshi: new)
        DownloadBubble.shared.show(on:navigationController!)
        
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
        if let circle = doujinshi.title.circleName , circle != artist {
            actions.append( UIPreviewAction(title: "Circle: \(circle)", style: .default) { (_, _) -> Void in
                self.delegate?.galleryDidSelectTag(text: "\(circle)" )
            })
        }
        if !doujinshi.isDownloaded && !doujinshi.isFavorite {
            actions.append( UIPreviewAction(title: "♥", style: .default) { (_, vc) -> Void in
                guard let vc = vc as? GalleryVC else {return}
                vc.addToFavorite()
            })
        }
        
        return actions
    }
}

protocol GalleryVCPreviewActionDelegate: class {
    func galleryDidSelectTag(text: String)
}

extension GalleryVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout ,UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return doujinshi.pages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageCell
        let page = doujinshi.pages[indexPath.item]
        if doujinshi.isDownloaded {
            cell.imageView.image = page.localImage
            cell.loadingView?.hide(animated: false)
        } else {
            if let image = ImageManager.shared.getCache(forKey: page.url) {
                cell.imageView.image = image
                cell.loadingView?.hide(animated: false)
            } else {
                cell.imageView.sd_setImage(with: URL(string: page.thumbUrl), placeholderImage: nil, options: [.handleCookies])
                cell.loadingView?.show(animated: false)
            }
        }
        cell.imageView.hero.id = "image_\(doujinshi.id)_\(indexPath.item)"
        cell.imageView.hero.modifiers = [.arc(intensity: 1), .forceNonFade]
        cell.imageView.isOpaque = true
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
        let urls = indexPaths.map{URL(string:doujinshi.pages[$0.item].thumbUrl)!}
        ImageManager.shared.prefetch(urls: urls)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !isPartDownloading {
            guard doujinshi.pages.count > 1 else {return}
            let vc = storyboard!.instantiateViewController(withIdentifier: "ViewerVC") as! ViewerVC
            vc.selectedIndexPath = indexPath
            vc.doujinshi = doujinshi
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
            if Defaults.Gallery.isAppendWhitePage {
                originalCellIndex = IndexPath(item: originalCellIndex.item - 1, section: originalCellIndex.section)
                currentCellIndex = IndexPath(item: currentCellIndex.item - 1, section: currentCellIndex.section)
            }
            if !collectionView.indexPathsForVisibleItems.contains(currentCellIndex) {
                collectionView.scrollToItem(at: currentCellIndex, at: originalCellIndex < currentCellIndex ? .bottom : .top, animated: false)
            }
        }
    }
    
    func heroDidEndAnimatingFrom(viewController: UIViewController) {
        if let _ = viewController as? ViewerVC {
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        }
    }
}
