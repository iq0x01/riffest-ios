import UIKit

class RMArtistService {
    class fileprivate func baseRequest(withURL urlString: String, onSuccess: @escaping (_ data: Data?) -> (), onError: @escaping (_ errorMessage: String) -> ()) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        let userToken = UserDefaults.standard.value(forKey: "token")
        let safeURL = urlString.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)
        var urlRequest = URLRequest(url: URL(string: safeURL!)!)
        if  userToken != nil {
            urlRequest.setValue("Bearer \(String(describing:userToken!))", forHTTPHeaderField: "Authorization")
        }
        let session = URLSession.shared
        DispatchQueue.main.async {
            let dataTask = session.dataTask(with: urlRequest, completionHandler: {(data, response, error) in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                if error != nil {
                    onError("\(error!)")
                }else {
                    let httpResponse = response as! HTTPURLResponse
                    let statusCode = httpResponse.statusCode
                    if statusCode == 200 {
                        onSuccess(data)
                    }else {
                        let statusCodeObj = HTTPStatusCode.init(statusCode: statusCode)
                        onError(statusCodeObj.statusDescription)
                    }
                }
            })
            dataTask.resume()
        }
    }
    // get all top artists
    class func onHandleGetTopArtist(_ url: String, _ next_page: Int, _ search:String,_ onSuccess: @escaping (
        _ artist: [RMArtists]
        ) -> (), onError: @escaping (_ errorMessage: String) -> ()) {
        let urlString = baseUrl+url+"?page=\(next_page)&search=\(search)"
        RMArtistService.baseRequest(withURL: urlString, onSuccess: { (data) in
            var artist: [RMArtists] = []
            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary {
                    if let songDic = json.value(forKey: "data") as? [NSDictionary] {
                        for dic in songDic {
                            let artists = RMArtists.init(withDictionary: dic)
                            artist.append(artists)
                        }
                    }
                    onSuccess(artist)
                }
            }catch {
                DispatchQueue.main.async {
                    AppStateHelper.shared.onHandleAlertNotifiError(title: alermsg)
                }
            }
        }) { (errorString) in
            onError(errorString)
        }
    }
    
    
   // artist view
    class func onHandleViewArtistProfile(_ url: String, _ onSuccess: @escaping (
        _ myplaylist: RMArtists?,
        _ follow: Bool
        ) -> (), onError: @escaping (_ errorMessage: String) -> ()) {
        let urlString = baseUrl+url
        RMArtistService.baseRequest(withURL: urlString, onSuccess: { (data) in
            let artist: RMArtists?
            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary {
                    if let songDic = json.value(forKey: "data") as? NSDictionary {
                         artist = RMArtists.init(withDictionary: songDic)
                        let followed = json.value(forKey: "follow") as? Bool
                        onSuccess(artist, followed!)
                    }
                    
                }
            }catch {
                DispatchQueue.main.async {
                    AppStateHelper.shared.onHandleAlertNotifiError(title: alermsg)
                }
            }
        }) { (errorString) in
            onError(errorString)
        }
    }
    
    // get song by artist id
    class func onHandleGetSongByID(_ url: String, _ onSuccess: @escaping (_ song: [RMSong]) -> (), onError: @escaping (_ errorMessage: String) -> ()) {
        let urlString = baseUrl+url
        RMArtistService.baseRequest(withURL: urlString, onSuccess: { (data) in
            var song: [RMSong] = []
            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary {
                    if let songDic = json.value(forKey: "data") as? [NSDictionary] {
                        for dic in songDic {
                            let songs = RMSong.init(withDictionary: dic)
                            song.append(songs)
                        }
                        onSuccess(song)
                    }
                }
            }catch {
                DispatchQueue.main.async {
                   // AppStateHelper.shared.onHandleAlertNotifiError(title: alermsg)
                }
            }
        }) { (errorString) in
            onError(errorString)
        }
    }
    
    // follow
    class func onHandleFollowAndUnfollow(_ url: String,_ Method: String, _ body: Dictionary<String, String>, onSuccess: @escaping (_ follow: Bool) -> () ){
        let session = URLSession.shared
        let ulrString =  NSURL(string: baseUrl + url)
        var request = URLRequest(url:  ulrString! as URL)
        let userToken = UserDefaults.standard.value(forKey: "token")
        if  userToken != nil {
            request.setValue("Bearer \(String(describing:userToken!))", forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = Method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        } catch let error {
            print("error===", error)
        }
        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            guard error == nil else {
                return
            }
            if data != nil {
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        onSuccess(true)
                    }else {
                        onSuccess(false)
                        DispatchQueue.main.async {
                            AppStateHelper.shared.onHandleAlertNotifiError(title: alermsg)
                        }
                    }
                }
            }
        })
        task.resume()
    }
    
}
