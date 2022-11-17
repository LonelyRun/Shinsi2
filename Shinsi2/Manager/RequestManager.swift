import Alamofire
import Kanna

class RequestManager {
    static let shared = RequestManager()
    
    var next: String?

    func getList(page: Int, search keyword: String? = nil, completeBlock block: (([Doujinshi], Int) -> Void)?) {
        
        if page == 0 {
            next = ""
        }
        guard let next = next else {
            return
        }
        
        let categoryFilters = Defaults.Search.categories.map {"f_\($0)=\(UserDefaults.standard.bool(forKey: $0) ? 1 : 0)"}.joined(separator: "&")
        var url = Defaults.URL.host + "/?"
        url += "\(categoryFilters)&f_apply=Apply+Filter" //Apply category filters
        url += "&advsearch=1&f_sname=on&f_stags=on" //Advance search
        url += "&inline_set=dm_t" //Set mode to Thumbnail View
        url += "&next=\(next)"
        if !Defaults.List.minimumPages.isEmpty || !Defaults.List.maximumPages.isEmpty {
            url += "&f_sp=o&f_spf=\(Defaults.List.minimumPages)&f_spt=\(Defaults.List.maximumPages)"
        }
        if let minimunrating = Defaults.List.minimumRating {
            url += "&f_sr=on&f_srdd=\(minimunrating)"
        }
        
        var cacheFavoritesTitles = false
        if var keyword = keyword?.lowercased() {
            if keyword.contains("favorites") {
                url = Defaults.URL.host + "/favorites.php?next=\(next)&inline_set=dm_t"
                if let number = Int(keyword.replacingOccurrences(of: "favorites", with: "")) {
                    url += "&favcat=\(number)"
                }
                cacheFavoritesTitles = page == 0
            } else if keyword.contains("popular") {
                if page == 0 {
                    url = Defaults.URL.host + "/popular?next=\(next)&inline_set=dm_t"
                } else {
                    block?([], 0)
                    return
                }
            } else if keyword.contains("watched") {
                 url = Defaults.URL.host + "/watched?next=\(next)&inline_set=dm_t"
            } else {
                if Defaults.List.isFilterLanguage && !Defaults.List.listLanguage.isEmpty {
                    keyword = "\(keyword) language:\(Defaults.List.listLanguage)"
                }
                url += "&f_search=\(keyword.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"
            }
        }
    
        AF.request(url, method: .get).responseString {[unowned self] response in
            switch response.result {
            case .success(let value):
                let html = value
                if let doc = try? Kanna.HTML(html: html, encoding: .utf8) {
                    var items: [Doujinshi] = []
//                    var lastLabel: Int = 0
                    self.next = nil
                    for navNode in doc.xpath("//div [@class='searchnav']") {
                        if let nextSrc = navNode.at_css("div a[id='unext']")?["href"], let urlComponent = URLComponents(string: nextSrc), let queryItems = urlComponent.queryItems {
                            
                            for item in queryItems {
                                if item.name == "next", let value = item.value {
                                    self.next = value
                                }
                            }
                        }
                    }
                    
                    for link in doc.xpath("//div [@class='gl1t']") {
                        if let aNode = link.at_css("div[class='gl3t'] a") {
                            if let href = aNode["href"], let imgUrl = aNode.at_css("img")?["src"], let title = aNode.at_css("img")?["title"] {
                                items.append(Doujinshi(value: ["coverUrl": imgUrl, "title": title, "url": href]))
                            }
                        }
                    }
                    
                    block?(items, 0)
                    if cacheFavoritesTitles {
                        DispatchQueue.global(qos: .userInteractive).async {
                            let favTitles = doc.xpath("//option [contains(@value, 'fav')]").filter { $0.text != nil }.map { $0.text! }
                            if favTitles.count == 10 { Defaults.List.favoriteTitles = favTitles }
                        }
                    }
                } else {
                    block?([], 0)
                }
            case .failure(_):
                block?([], 0)
            }
        }
    }
    
    func getDoujinshi(doujinshi: Doujinshi, at page: Int, completeBlock block: (([Page]) -> Void)?) {
        print(#function)
        var url = doujinshi.url + "?p=\(page)"
        url += "&inline_set=ts_l" //Set thumbnal size to large
        AF.request(url, method: .get).responseString { response in
            switch response.result {
            case .success(let value):
                if let doc = try? Kanna.HTML(html: value, encoding: String.Encoding.utf8) {
                    var pages: [Page] = []
                    for link in doc.xpath("//div [@class='gdtl'] //a") {
                        if let url = link["href"] {
                            if let imgNode = link.at_css("img"), let thumbUrl = imgNode["src"] {
                                let page = Page(value: ["thumbUrl": thumbUrl, "url": url])
                                page.photo = SSPhoto(URL: url)
                                pages.append(page)
                            }
                        }
                    }
                    
                    if page == 0 {
                        doujinshi.isFavorite = doc.xpath("//div [@class='i']").count != 0
                        //Parse comments
                        let commentDateFormatter = DateFormatter()
                        commentDateFormatter.dateFormat = "dd MMMM  yyyy, HH:mm zzz"
                        for c in doc.xpath("//div [@id='cdiv'] //div [@class='c1']") {
                            if let dateAndAuthor = c.at_xpath("div [@class='c2'] /div [@class='c3']")?.text,
                                let author = c.at_xpath("div [@class='c2'] /div [@class='c3'] /a")?.text,
                                let text = c.at_xpath("div [@class='c6']")?.innerHTML {
                                let dateString = dateAndAuthor.replacingOccurrences(of: author, with: "").replacingOccurrences(of: "Posted on ", with: "").replacingOccurrences(of: " by:   ", with: "")
                                let r = Comment(author: author, date: commentDateFormatter.date(from: dateString) ?? Date(), text: text)
                                doujinshi.comments.append(r)
                            }
                        }
                        doujinshi.perPageCount = pages.count
                    }
                    block?(pages)
                } else {
                    block?([])
                }
            case .failure(_):
                block?([])
            }
        }
    }

    func getPageImageUrl(url: String, completeBlock block: ( (_ imageURL: String?) -> Void )?) {
        print(#function)
        AF.request(url, method: .get).responseString { response in
            switch response.result {
            case .success(let value):
                if let doc = try? Kanna.HTML(html: value, encoding: String.Encoding.utf8) {
                    if let imageURL =  doc.at_xpath("//img [@id='img']")?["src"] {
                        block?(imageURL)
                        return
                    }
                }
                block?(nil)
            case .failure(_):
                block?(nil)
            }
        }
    }

    
    func getGData( doujinshi: Doujinshi, completeBlock block: ((GData?) -> Void)? ) {
        print(#function)
        //Api http://ehwiki.org/wiki/API
        guard doujinshi.isIdTokenValide else { block?(nil); return}
        
        let p: [String: Any] = [
            "method": "gdata",
            "gidlist": [ [ doujinshi.id, doujinshi.token ] ],
            "namespace": 1
        ]
        
        AF.request(Defaults.URL.host + "/api.php", method: .post, parameters: p, encoding: JSONEncoding(), headers: nil).responseJSON { response in
            switch response.result {
            case .success(let value):
                if let dic = value as? NSDictionary {
                    if let metadatas = dic["gmetadata"] as? NSArray {
                        if let metadata = metadatas[0] as? NSDictionary {
                            if let count = metadata["filecount"]  as? String,
                                let rating = metadata["rating"] as? String,
                                let category = metadata["category"] as? String,
                                let posted = metadata["posted"] as? String,
                                let title = metadata["title"] as? String,
                                let title_jpn = metadata["title_jpn"] as? String,
                                let tags = metadata["tags"] as? [String],
                                let thumb = metadata["thumb"] as? String,
                                let uploader = metadata["uploader"] as? String,
                                let gid = metadata["gid"] as? Int {
                                let gdata = GData(value:
                                                    ["filecount": Int(count)!,
                                                     "rating": Float(rating)!,
                                                     "category": category,
                                                     "posted": posted,
                                                     "title": title.isEmpty ? doujinshi.title : title,
                                                     "title_jpn": title_jpn.isEmpty ? doujinshi.title: title_jpn,
                                                     "coverUrl": thumb,
                                                     "gid": String(gid),
                                                     "uploader": uploader
                                                    ])
                                for t in tags {
                                    gdata.tags.append(Tag(value: ["name": t]))
                                }
                                block?(gdata)
                                //Cache
                                let cachedURLResponse = CachedURLResponse(response: response.response!, data: response.data!, userInfo: nil, storagePolicy: .allowed)
                                URLCache.shared.storeCachedResponse(cachedURLResponse, for: response.request!)
                                return
                            }
                        }
                    }
                    block?(nil)
                }
            case .failure(_):
                block?(nil)
            }
        }
    }

    func login(username name: String, password pw: String, completeBlock block: ((AFDataResponse<String>) -> Void)? ) {
        let url = Defaults.URL.login.absoluteString + "&CODE=01"
        let parameters: [String: String] = [
            "CookieDate": "1",
            "b": "d",
            "bt": "1-1",
            "UserName": name,
            "PassWord": pw,
            "ipb_login_submit": "Login!"]
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(), headers: nil).responseString { string in
            block?(string)
        }
    }

    func addDoujinshiToFavorite(doujinshi: Doujinshi, category: Int = 0) {
        guard doujinshi.isIdTokenValide else {return}
        doujinshi.isFavorite = true
        let url = Defaults.URL.host + "/gallerypopups.php?gid=\(doujinshi.id)&t=\(doujinshi.token)&act=addfav"
        let parameters: [String: String] = ["favcat": "\(category)", "favnote": "", "apply": "Add to Favorites", "update": "1"]
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(), headers: nil).responseString { _ in
        }
    }

    func deleteFavorite(doujinshi: Doujinshi) {
        guard doujinshi.isIdTokenValide else {return}
        let url = Defaults.URL.host + "/favorites.php"
        let parameters: [String: Any] = ["ddact": "delete", "modifygids[]": doujinshi.id, "apply": "Apply"]
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(), headers: nil).responseString { _ in
        }
    }
    
    func moveFavorite(doujinshi: Doujinshi, to catogory: Int) {
        guard 0...9 ~= catogory else {return}
        guard doujinshi.isIdTokenValide else {return}
        let url = Defaults.URL.host + "/favorites.php"
        let parameters: [String: Any] = ["ddact": "fav\(catogory)", "modifygids[]": doujinshi.id, "apply": "Apply"]
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(), headers: nil).responseString { _ in
        }
    }
}
