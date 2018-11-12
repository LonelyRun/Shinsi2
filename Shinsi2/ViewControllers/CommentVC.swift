import UIKit

class CommentVC: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    var comments: [Comment] = []
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    } 
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CommentCell
        let c = comments[indexPath.row]
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd HH:mm"
        cell.dateLabel.text = df.string(from: c.date)
        cell.authorLabel.text = c.author
        cell.commentLabel.attributedText = c.textHtml
        
        return cell
    }

}
