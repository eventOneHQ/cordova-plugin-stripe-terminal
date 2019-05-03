import StripeTerminal
import Alamofire

class APIClient: ConnectionTokenProvider {
    
    var apiUrl: String
    
    init(apiUrl: String) {
        self.apiUrl = apiUrl
        print("init TokenProvider")
    }

    // Your backend should call v1/terminal/connection_tokens and return the JSON response from Stripe
    func fetchConnectionToken(_ completion: @escaping ConnectionTokenCompletionBlock) {
        print("fetchConnectionToken")
        print(apiUrl)

        Alamofire.request(apiUrl, method: .get)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    let json = value as! [String: AnyObject]
                    print(json["secret"])
                    completion(json["secret"], nil)
                case .failure(let error):
                    print(error)
                    completion(nil, error)
                }
        }
    }
}