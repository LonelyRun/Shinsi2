import UIKit
import Hero
import AloeStackView

class TagVC: BaseViewController {
    weak var doujinshi: Doujinshi!
    var clickBlock: ((String) -> Void)?
    struct TagItem {
        var title: String
        var tags: [String]
        var sortNumber: Int 
    }
    var sortedStrings = ["parody","artist","group","character","female","male","misc","language"]
    var items : [TagItem] = []
    let stackView = AloeStackView()
    private var backGesture: InteractiveBackGesture?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = UIColor(white: 0, alpha: 0.5)
        backGesture = InteractiveBackGesture(viewController: self, toView: stackView, mode: .modal, isSimultaneously: true)
        
        let gTag = doujinshi.gdata!.gTag
        let keys = gTag.allProperties().keys
        for key in keys {
            if gTag[key].count != 0 {
                let item = TagItem(title: key, tags: gTag[key], sortNumber: sortedStrings.index(of: key) ?? 999)
                items.append(item)
            }
        }
        items = items.sorted{$0.sortNumber < $1.sortNumber}
        
        view.addSubview(stackView)
        stackView.frame = view.bounds
        stackView.separatorInset = .zero
        stackView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        
        for item in items {
            stackView.addRow(createTitleLable(text: item.title))
            for tag in item.tags {
                let l = createTextLable(text: tag)
                l.isUserInteractionEnabled = true
                stackView.addRow(l)
                stackView.hideSeparator(forRow: l)
                stackView.setInset(forRow: l, inset: UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15))
                stackView.setTapHandler(forRow: l) {[weak self] (label) in
                    let string = item.title == "misc" ? tag : item.title + ":" + tag
                    self?.clickBlock?(string)
                }
            }
        }
    }
    
    func createTitleLable(text:String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = UIColor.darkGray
        return label
    }
    
    func createTextLable(text:String) -> UILabel {
        let label = UILabel()
        label.text = text
        return label
    }
}
